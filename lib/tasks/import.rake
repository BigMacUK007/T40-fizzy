# frozen_string_literal: true

namespace :fizzy do
  desc "Import data from fizzy.do export ZIP file"
  task :import, [:zip_path, :user_email] => :environment do |_t, args|
    zip_path = args[:zip_path]
    user_email = args[:user_email]

    abort "Usage: bin/rails fizzy:import[/path/to/export.zip,user@example.com]" unless zip_path && user_email
    abort "ZIP file not found: #{zip_path}" unless File.exist?(zip_path)

    user = User.joins(:identity).find_by(identities: { email_address: user_email })
    abort "User not found with email: #{user_email}" unless user

    importer = FizzyImporter.new(zip_path, user)
    importer.import!
  end
end

class FizzyImporter
  def initialize(zip_path, user)
    @zip_path = zip_path
    @user = user
    @account = user.account
    @boards = {}
    @columns = {}
    @stats = { boards: 0, cards: 0, comments: 0, attachments: 0, skipped: 0 }
  end

  def import!
    puts "Starting import from #{@zip_path}"
    puts "Importing as user: #{@user.name} (#{@user.identity.email_address})"
    puts "Into account: #{@account.name}"
    puts "-" * 50

    # Set Current context for model defaults
    Current.user = @user

    Zip::File.open(@zip_path) do |zip|
      json_entries = zip.glob("*.json").sort_by { |e| e.name.to_i }

      puts "Found #{json_entries.count} cards to import"
      puts

      json_entries.each_with_index do |entry, index|
        import_card_from_entry(zip, entry)
        print "\rProgress: #{index + 1}/#{json_entries.count}"
      end
    end

    puts "\n\n" + "=" * 50
    puts "Import complete!"
    puts "  Boards created:  #{@stats[:boards]}"
    puts "  Cards imported:  #{@stats[:cards]}"
    puts "  Comments:        #{@stats[:comments]}"
    puts "  Attachments:     #{@stats[:attachments]}"
    puts "  Skipped:         #{@stats[:skipped]}"
    puts "=" * 50
  end

  private

  def import_card_from_entry(zip, entry)
    data = JSON.parse(entry.get_input_stream.read)
    card_number = entry.name.gsub(".json", "").to_i

    # Skip if card already exists
    if @account.cards.exists?(number: card_number)
      @stats[:skipped] += 1
      return
    end

    board = find_or_create_board(data["board"])
    column = find_or_create_column(board, data["status"])

    card = create_card(board, column, data, card_number)
    import_comments(card, data["comments"] || [])
    import_attachments(zip, card, card_number)

    @stats[:cards] += 1
  rescue => e
    puts "\nError importing card #{entry.name}: #{e.message}"
    @stats[:skipped] += 1
  end

  def find_or_create_board(board_name)
    @boards[board_name] ||= begin
      board = @account.boards.find_by(name: board_name)

      unless board
        board = @account.boards.create!(
          name: board_name,
          creator: @user
        )
        @stats[:boards] += 1
      end

      board
    end
  end

  def find_or_create_column(board, status)
    return nil if status.in?(["Done", "Not now", "Maybe?"])

    key = "#{board.id}:#{status}"
    @columns[key] ||= begin
      column = board.columns.find_by(name: status)

      unless column
        position = board.columns.count
        column = board.columns.create!(
          name: status,
          position: position,
          account: @account
        )
      end

      column
    end
  end

  def create_card(board, column, data, card_number)
    created_time = Time.parse(data["created_at"])
    updated_time = Time.parse(data["updated_at"])

    card = Card.new(
      account: @account,
      board: board,
      column: column,
      creator: @user,
      title: data["title"],
      status: "published",
      created_at: created_time,
      updated_at: updated_time,
      last_active_at: updated_time
    )

    # Skip number auto-assignment
    card.number = card_number

    # Set description via ActionText
    if data["description"].present?
      card.description = ActionText::Content.new(data["description"])
    end

    # Save without callbacks that would trigger events
    card.save!(validate: false)

    # Handle special statuses
    case data["status"]
    when "Done"
      card.close(user: @user)
    when "Not now"
      card.postpone(user: @user)
    end

    card
  end

  def import_comments(card, comments)
    comments.each do |comment_data|
      comment = card.comments.new(
        account: @account,
        creator: @user,
        created_at: Time.parse(comment_data["created_at"])
      )

      if comment_data["body"].present?
        comment.body = ActionText::Content.new(comment_data["body"])
      end

      comment.save!
      @stats[:comments] += 1
    end
  end

  def import_attachments(zip, card, card_number)
    # Find attachment entries for this card
    attachment_entries = zip.glob("#{card_number}/*")

    attachment_entries.each do |entry|
      filename = File.basename(entry.name)
      # Remove the blob key prefix (format: key_filename)
      actual_filename = filename.sub(/^[a-zA-Z0-9]+_/, "")

      begin
        tempfile = Tempfile.new([actual_filename, File.extname(actual_filename)])
        tempfile.binmode
        tempfile.write(entry.get_input_stream.read)
        tempfile.rewind

        card.attachments.attach(
          io: tempfile,
          filename: actual_filename,
          content_type: Marcel::MimeType.for(name: actual_filename)
        )

        @stats[:attachments] += 1
      rescue => e
        puts "\nWarning: Could not import attachment #{entry.name}: #{e.message}"
      ensure
        tempfile&.close
        tempfile&.unlink
      end
    end
  end
end
