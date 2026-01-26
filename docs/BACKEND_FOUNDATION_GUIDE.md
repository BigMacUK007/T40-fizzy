# Fizzy Backend Foundation Guide

**A comprehensive handover document for backend developers**

This guide documents the backend architecture, patterns, and conventions used in Fizzy. It serves as the foundation for building robust, maintainable Ruby on Rails applications following 37signals/Basecamp conventions.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Multi-Tenancy](#2-multi-tenancy)
3. [Current Context Pattern](#3-current-context-pattern)
4. [Models & Domain Design](#4-models--domain-design)
5. [Concerns & Composition](#5-concerns--composition)
6. [Controllers & REST](#6-controllers--rest)
7. [Authentication & Authorization](#7-authentication--authorization)
8. [Background Jobs](#8-background-jobs)
9. [Event System & Notifications](#9-event-system--notifications)
10. [Mailers](#10-mailers)
11. [Database & UUIDs](#11-database--uuids)
12. [Full-Text Search](#12-full-text-search)
13. [Testing Patterns](#13-testing-patterns)
14. [Configuration & Environment](#14-configuration--environment)
15. [Code Style & Conventions](#15-code-style--conventions)
16. [Quick Reference](#16-quick-reference)

---

## 1. Architecture Overview

### Core Principles

1. **Vanilla Rails** - No service layers, no complex abstractions. Rich models, thin controllers.
2. **Multi-Tenancy** - URL-based tenant isolation without subdomains or separate databases.
3. **Concernification** - Models composed of focused, reusable concerns.
4. **Event-Driven** - All significant actions tracked as events, driving notifications and webhooks.
5. **Async-First** - Background jobs automatically inherit tenant context.
6. **REST Purity** - State changes modeled as resources (closures, triages, not_nows).

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Rails 8+ | Full-stack web framework |
| **Database** | MySQL/SQLite | Primary data store |
| **Background Jobs** | Solid Queue | Database-backed job queue |
| **Real-time** | Turbo Streams | WebSocket broadcasts |
| **Rich Text** | Action Text | WYSIWYG content |
| **File Storage** | Active Storage | Attachments |
| **Caching** | Solid Cache | Database-backed cache |

### Directory Structure

```
app/
├── controllers/
│   ├── concerns/              # Controller mixins
│   ├── cards/                 # Nested card actions
│   ├── boards/                # Nested board actions
│   └── [resource]_controller.rb
├── models/
│   ├── concerns/              # Model mixins
│   ├── card/                  # Card submodules (25+)
│   ├── board/                 # Board submodules
│   ├── user/                  # User submodules
│   ├── notifier/              # Notification strategies
│   └── search/                # Search shards
├── jobs/
│   ├── card/                  # Card-related jobs
│   ├── notification/          # Notification jobs
│   └── concerns/              # Job mixins
├── mailers/
│   └── concerns/              # Mailer mixins
└── views/
    └── [resource]/            # View templates

config/
├── initializers/
│   ├── tenanting/             # Multi-tenancy setup
│   └── [feature].rb           # Feature configs
├── recurring.yml              # Scheduled jobs
└── queue.yml                  # Solid Queue config

lib/
├── fizzy.rb                   # App configuration
└── rails_ext/                 # Rails extensions
    ├── active_record_uuid_type.rb
    └── [extension].rb

test/
├── controllers/               # Integration tests
├── models/                    # Unit tests
│   └── card/                  # Concern tests
├── jobs/                      # Job tests
├── mailers/                   # Mailer tests
├── system/                    # Browser tests
└── test_helpers/              # Test utilities
```

---

## 2. Multi-Tenancy

### URL-Based Tenant Isolation

Fizzy uses **path-based multi-tenancy** where each account has a unique URL prefix:

```
https://fizzy.do/1234567/boards/abc123
              ↑
        Account ID (7+ digits)
```

### How It Works

**Middleware:** `AccountSlug::Extractor`

Located in `config/initializers/tenanting/account_slug.rb`:

```ruby
class AccountSlug::Extractor
  PATTERN = /(\d{7,})/                    # 7+ digit account ID
  PATH_INFO_MATCH = /\A(\/#{PATTERN})/    # At start of path

  def call(env)
    if path_match = env["PATH_INFO"].match(PATH_INFO_MATCH)
      slug = path_match[1]
      external_id = path_match[2]

      # Move slug from PATH_INFO to SCRIPT_NAME
      env["SCRIPT_NAME"] = slug
      env["PATH_INFO"] = env["PATH_INFO"].delete_prefix(slug)
      env["fizzy.external_account_id"] = external_id

      # Lookup and set account context
      if account = Account.find_by(external_account_id: external_id)
        Current.with_account(account) { @app.call(env) }
      else
        # Handle missing account...
      end
    else
      @app.call(env)
    end
  end
end
```

### Request Flow

```
Request: GET /1234567/boards/123

1. Middleware extracts: 1234567 (external_account_id)
2. Moves to SCRIPT_NAME: /1234567
3. Updates PATH_INFO: /boards/123
4. Looks up: Account.find_by(external_account_id: 1234567)
5. Sets: Current.with_account(account) { ... }
6. Rails sees: /boards/123 (mounted at /1234567)
7. Controller: Current.account is available
```

### Benefits

- No subdomain complexity
- Simple local development
- All routes remain standard RESTful paths
- Easy testing (just set script_name)

### Account Model

```ruby
class Account < ApplicationRecord
  EXTERNAL_ACCOUNT_ID_MIN = 1_000_000  # 7 digits minimum

  has_many :users, :boards, :cards, :tags, :webhooks
  has_one :system_user, -> { system }, class_name: "User"

  before_create :assign_external_account_id

  def slug
    AccountSlug.encode(external_account_id)  # Returns "/1234567"
  end

  private
    def assign_external_account_id
      self.external_account_id ||= Account::ExternalIdSequence.next
    end
end
```

### Data Isolation

All tenant-scoped models include `account_id`:

```ruby
class Card < ApplicationRecord
  belongs_to :account

  # All queries automatically scoped
  default_scope { where(account: Current.account) if Current.account }
end
```

---

## 3. Current Context Pattern

### Thread-Local State

`Current` provides request-scoped attributes using `ActiveSupport::CurrentAttributes`:

**File:** `app/models/current.rb`

```ruby
class Current < ActiveSupport::CurrentAttributes
  # Core context
  attribute :session, :user, :identity, :account

  # Request metadata
  attribute :http_method, :request_id, :user_agent, :ip_address

  # Derived attributes
  def session=(value)
    super(value)
    self.identity = session.identity if value.present?
  end

  def user
    super || identity&.user_for(account)
  end

  # Scoping helper
  def with_account(value, &)
    with(account: value, &)
  end
end
```

### Usage Everywhere

```ruby
# In controllers
Current.user              # Authenticated user
Current.account           # Current tenant
Current.identity          # Global email identity

# In models
class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  def track_event(action)
    events.create!(creator: Current.user, ...)
  end
end

# In jobs (automatically restored)
class MyJob < ApplicationJob
  def perform(record)
    Current.account  # Available! (restored from serialization)
  end
end
```

### Setting Context

```ruby
# In middleware (automatic)
Current.with_account(account) { @app.call(env) }

# In tests
setup do
  Current.account = accounts("37s")
end

teardown do
  Current.clear_all
end

# Manual context switching
Current.with(account: other_account, user: admin_user) do
  # Temporarily different context
end
```

---

## 4. Models & Domain Design

### Core Domain Models

```
Account (Tenant)
├── User (Account membership)
│   └── Identity (Global email - shared across accounts)
├── Board (Project/workspace)
│   ├── Column (Workflow stage)
│   ├── Access (User permissions)
│   └── Webhook
├── Card (Work item/task)
│   ├── Assignment (Assignee)
│   ├── Comment
│   ├── Tag (via Tagging)
│   ├── Step (Checklist item)
│   ├── Closure (Closed state)
│   ├── NotNow (Postponed state)
│   ├── Goldness (Highlighted)
│   ├── Watch (Subscriber)
│   ├── Pin (User bookmark)
│   └── ActivitySpike
├── Event (Audit trail)
├── Notification
└── Tag
```

### Rich Domain Models

Models contain business logic, not services:

```ruby
class Card < ApplicationRecord
  # 25+ concerns composing card behavior
  include Assignable, Closeable, Postponable, Triageable, Golden,
          Taggable, Searchable, Watchable, Eventable, Readable,
          Colored, Stallable, Pinnable, Broadcastable, Entropic,
          Attachments, Mentions, Multistep, Storage::Tracked,
          Exportable, Promptable, Statuses

  belongs_to :account
  belongs_to :board
  belongs_to :column, optional: true
  belongs_to :creator, class_name: "User"

  has_rich_text :description
  has_one_attached :image

  # Business methods (not in services!)
  def close(user: Current.user)
    closure = closures.create!(closer: user)
    track_event :closed
    closure
  end

  def triage_into(column)
    update!(column: column)
    track_event :triaged, particulars: { column_id: column.id }
  end
end
```

### State as Relationships

State changes are modeled as **has_one** relationships:

```ruby
class Card < ApplicationRecord
  has_one :closure      # Card is closed if this exists
  has_one :not_now      # Card is postponed if this exists
  has_one :goldness     # Card is highlighted if this exists

  def closed?
    closure.present?
  end

  def postponed?
    not_now.present?
  end

  def golden?
    goldness.present?
  end
end
```

This pattern enables:
- Audit trail (who/when)
- Easy querying (joins vs boolean flags)
- RESTful state management

### Scopes for Common Queries

```ruby
class Card < ApplicationRecord
  # State scopes
  scope :open, -> { where.missing(:closure) }
  scope :closed, -> { joins(:closure) }
  scope :active, -> { open.published.where.missing(:not_now) }
  scope :postponed, -> { joins(:not_now) }

  # Ordering
  scope :latest, -> { order(last_active_at: :desc, id: :desc) }
  scope :with_golden_first, -> {
    left_outer_joins(:goldness)
      .prepend_order("card_goldnesses.id IS NULL")
      .preload(:goldness)
  }

  # Eager loading
  scope :preloaded, -> {
    with_users.preload(:column, :tags, :closure, :not_now, :goldness)
  }
  scope :with_users, -> { preload(:creator, :assignees) }
end
```

---

## 5. Concerns & Composition

### Model Concerns

Large models are decomposed into focused concerns:

**File:** `app/models/card/assignable.rb`

```ruby
module Card::Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, dependent: :destroy
    has_many :assignees, through: :assignments
  end

  def assigned_to?(user)
    assignees.include?(user)
  end

  def toggle_assignment(user)
    assigned_to?(user) ? unassign(user) : assign(user)
  end

  def assign(user)
    return if assignments.count >= Assignment::LIMIT

    assignments.create!(assignee: user, assigner: Current.user)
    watch_by(user)
    track_event(:assigned, particulars: { assignee_id: user.id })
  end

  def unassign(user)
    assignments.find_by(assignee: user)&.destroy
    track_event(:unassigned, particulars: { assignee_id: user.id })
  end
end
```

**File:** `app/models/card/closeable.rb`

```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
    scope :open, -> { where.missing(:closure) }
    scope :closed, -> { joins(:closure) }
  end

  def closed?
    closure.present?
  end

  def close(user: Current.user)
    transaction do
      create_closure!(closer: user)
      track_event(:closed)
    end
  end

  def reopen(user: Current.user)
    transaction do
      closure.destroy!
      track_event(:reopened)
    end
  end
end
```

### Shared Concerns

**File:** `app/models/concerns/eventable.rb`

```ruby
module Eventable
  extend ActiveSupport::Concern

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    board.events.create!(
      action: "#{eventable_prefix}_#{action}",
      creator: creator,
      board: board,
      eventable: self,
      particulars: particulars
    )
  end

  private
    def eventable_prefix
      self.class.name.underscore  # "card" or "comment"
    end
end
```

**File:** `app/models/concerns/mentions.rb`

```ruby
module Mentions
  extend ActiveSupport::Concern

  included do
    has_many :mentions, as: :mentionable, dependent: :destroy
    has_many :mentionees, through: :mentions, source: :user

    after_save_commit :create_mentions_later, if: :should_process_mentions?
  end

  def create_mentions(mentioner:)
    mentioned_users.each do |user|
      mentions.find_or_create_by!(user: user, mentioner: mentioner)
    end
  end

  private
    def mentioned_users
      # Parse rich text for @mentions
      mentioned_emails = rich_text_body&.body&.to_s&.scan(/@(\S+@\S+)/)&.flatten || []
      User.where(email_address: mentioned_emails)
    end

    def create_mentions_later
      Mention::CreateJob.perform_later(self, mentioner: Current.user)
    end
end
```

**File:** `app/models/concerns/searchable.rb`

```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit  :index_for_search
    after_update_commit  :reindex_for_search
    after_destroy_commit :remove_from_search
  end

  def index_for_search
    Search::Record.index(self)
  end

  def reindex_for_search
    Search::Record.reindex(self)
  end

  def remove_from_search
    Search::Record.remove(self)
  end
end
```

### Controller Concerns

**File:** `app/controllers/concerns/card_scoped.rb`

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card
    before_action :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        dom_id(@card),
        partial: "cards/card",
        locals: { card: @card }
      )
    end
end
```

**File:** `app/controllers/concerns/authentication.rb`

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_authenticated_user, **options
    end
  end

  private
    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      if session = find_session_by_cookie
        Current.session = session
        true
      end
    end

    def start_new_session_for(identity)
      identity.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      ).tap do |session|
        set_session_cookie(session)
        Current.session = session
      end
    end

    def authenticated?
      Current.session.present?
    end
end
```

---

## 6. Controllers & REST

### Thin Controllers

Controllers are thin dispatchers to rich models:

```ruby
class CardsController < ApplicationController
  before_action :set_board, only: [:create]
  before_action :set_card, except: [:index, :create]

  def index
    @cards = Current.user.accessible_cards.active.latest.page(params[:page])
  end

  def show
    @card.mark_as_read_by(Current.user)
  end

  def create
    @card = @board.cards.create!(card_params.merge(creator: Current.user))
    respond_to do |format|
      format.html { redirect_to @card }
      format.json { render json: @card, status: :created, location: @card }
    end
  end

  def update
    @card.update!(card_params)
    respond_to do |format|
      format.turbo_stream
      format.json { render json: @card }
    end
  end

  def destroy
    @card.destroy!
    respond_to do |format|
      format.html { redirect_to @board }
      format.json { head :no_content }
    end
  end

  private
    def set_board
      @board = Current.user.boards.find(params[:board_id])
    end

    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:id])
    end

    def card_params
      params.require(:card).permit(:title, :description, :image, :column_id)
    end
end
```

### Action-as-Resource Pattern

State changes are modeled as nested resources:

```ruby
# config/routes.rb
resources :cards do
  resource :closure, only: [:create, :destroy]    # close/reopen
  resource :triage, only: [:create, :destroy]     # column placement
  resource :goldness, only: [:create, :destroy]   # highlight
  resource :not_now, only: [:create]              # postpone
  resources :assignments, only: [:new, :create, :destroy]
  resources :comments
  resources :tags, controller: "cards/taggings"
end
```

**Controller for state change:**

```ruby
# app/controllers/cards/closures_controller.rb
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :created }
    end
  end

  def destroy
    @card.reopen
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

### Multiple Response Formats

Controllers support HTML, Turbo Stream, and JSON:

```ruby
def update
  @card.update!(card_params)

  respond_to do |format|
    format.html { redirect_to @card, notice: "Card updated" }
    format.turbo_stream  # Renders update.turbo_stream.erb
    format.json { render json: @card }
  end
end
```

### Authorization in Controllers

```ruby
class BoardsController < ApplicationController
  before_action :set_board, except: [:index, :new, :create]
  before_action :ensure_permission_to_admin_board, only: [:update, :destroy]

  private
    def set_board
      @board = Current.user.boards.find(params[:id])
    end

    def ensure_permission_to_admin_board
      unless Current.user.admin? || @board.creator == Current.user
        head :forbidden
      end
    end
end
```

---

## 7. Authentication & Authorization

### Passwordless Magic Links

No passwords - authentication via email magic links:

```ruby
class Identity < ApplicationRecord
  has_many :magic_links
  has_many :sessions
  has_many :users  # Can have users in multiple accounts

  def send_magic_link(for: :sign_in)
    magic_links.create!.tap do |link|
      MagicLinkMailer.sign_in_instructions(link).deliver_later
    end
  end
end

class MagicLink < ApplicationRecord
  belongs_to :identity

  has_secure_token :token
  generates_token_for :authentication, expires_in: 30.minutes

  before_create :generate_code

  def verify(code)
    code == self.code && !expired?
  end

  private
    def generate_code
      self.code = MagicLink::Code.generate  # 6-digit code
    end
end
```

### Session Management

```ruby
class Session < ApplicationRecord
  belongs_to :identity

  has_secure_token

  def self.authenticate(token)
    find_by(token: token)
  end
end
```

### Authentication Flow

```ruby
# 1. User enters email
class SessionsController < ApplicationController
  require_unauthenticated_access

  def create
    if identity = Identity.find_by(email_address: params[:email_address])
      identity.send_magic_link
      redirect_to session_magic_link_path
    else
      redirect_to new_signup_path(email: params[:email_address])
    end
  end
end

# 2. User enters code from email
class Sessions::MagicLinksController < ApplicationController
  def create
    magic_link = MagicLink.find_by_token_for(:authentication, params[:token])

    if magic_link&.verify(params[:code])
      start_new_session_for(magic_link.identity)
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Invalid code"
    end
  end
end
```

### User Roles

```ruby
# app/models/user/role.rb
module User::Role
  extend ActiveSupport::Concern

  ROLES = %w[owner admin member system].freeze

  included do
    enum :role, ROLES.index_by(&:itself), default: :member
  end

  def admin_or_owner?
    admin? || owner?
  end

  def can_admin_board?(board)
    admin_or_owner? || board.creator == self
  end
end
```

### Board-Level Access

```ruby
class Access < ApplicationRecord
  belongs_to :user
  belongs_to :board

  enum :involvement, { access_only: 0, watching: 1 }
end

class Board < ApplicationRecord
  has_many :accesses
  has_many :users_with_access, through: :accesses, source: :user

  def accessible_to?(user)
    all_access? || accesses.exists?(user: user) || user.admin_or_owner?
  end
end
```

---

## 8. Background Jobs

### Solid Queue

Fizzy uses **Solid Queue** - a database-backed job queue (no Redis required).

**File:** `config/queue.yml`

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 5
      polling_interval: 0.1

production:
  <<: *default
  workers:
    - queues: [backend, mailers, default]
      threads: 5
    - queues: [webhooks]
      threads: 3
```

### ApplicationJob

```ruby
class ApplicationJob < ActiveJob::Base
  # Retry configuration
  # retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
end
```

### Automatic Account Context

Jobs automatically capture and restore tenant context:

**File:** `config/initializers/active_job.rb`

```ruby
module FizzyActiveJobExtensions
  extend ActiveSupport::Concern

  prepended do
    attr_reader :account
    self.enqueue_after_transaction_commit = true
  end

  def initialize(...)
    super
    @account = Current.account  # Capture at enqueue time
  end

  def serialize
    super.merge("account" => @account&.to_gid)
  end

  def deserialize(job_data)
    super
    if gid = job_data.fetch("account", nil)
      @account = GlobalID::Locator.locate(gid)
    end
  end

  def perform_now
    if account.present?
      Current.with_account(account) { super }  # Restore at perform time
    else
      super
    end
  end
end

ActiveJob::Base.prepend(FizzyActiveJobExtensions)
```

### Job Patterns

**Shallow jobs that delegate to models:**

```ruby
# app/jobs/mention/create_job.rb
class Mention::CreateJob < ApplicationJob
  def perform(record, mentioner:)
    record.create_mentions(mentioner: mentioner)
  end
end

# app/jobs/event/webhook_dispatch_job.rb
class Event::WebhookDispatchJob < ApplicationJob
  include ActiveJob::Continuable  # Resumable job

  queue_as :webhooks

  def perform(event)
    step :dispatch do |step|
      Webhook.active.triggered_by(event).find_each(start: step.cursor) do |webhook|
        webhook.trigger(event)
        step.advance! from: webhook.id
      end
    end
  end
end
```

**Model methods that enqueue jobs:**

```ruby
# Naming convention: _later for async, _now for sync
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    # Actual relay logic
  end
end
```

### Recurring Jobs

**File:** `config/recurring.yml`

```yaml
production: &production
  # Notifications
  deliver_bundled_notifications:
    command: "Notification::Bundle.deliver_all_later"
    schedule: every 30 minutes

  # Cleanup
  auto_postpone_all_due:
    command: "Card.auto_postpone_all_due"
    schedule: every hour at minute 50

  delete_unused_tags:
    class: DeleteUnusedTagsJob
    schedule: every day at 04:02

  cleanup_magic_links:
    command: "MagicLink.cleanup"
    schedule: every 4 hours

  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches"
    schedule: every hour at minute 12

development: *production
```

---

## 9. Event System & Notifications

### Event Model

All significant actions are recorded as events:

```ruby
class Event < ApplicationRecord
  belongs_to :account
  belongs_to :board
  belongs_to :creator, class_name: "User"
  belongs_to :eventable, polymorphic: true  # Card, Comment, etc.

  include Notifiable, Particulars, Promptable

  # Actions like: card_created, card_closed, comment_added
  attribute :action, :string

  # Flexible metadata storage
  attribute :particulars, :json, default: {}
end
```

### Creating Events

```ruby
# Via Eventable concern
class Card < ApplicationRecord
  include Eventable

  def close
    transaction do
      create_closure!(closer: Current.user)
      track_event(:closed)  # Creates Event record
    end
  end
end
```

### Notification System

Events drive notifications through the Notifier strategy pattern:

```ruby
# app/models/notifier.rb
class Notifier
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def self.for(source)
    case source
    when Event
      notifier_class = "Notifier::#{source.eventable.class}EventNotifier"
      notifier_class.safe_constantize&.new(source)
    when Mention
      Notifier::MentionNotifier.new(source)
    end
  end

  def notify
    recipients.each do |user|
      Notification.create!(user: user, source: source, creator: creator)
    end
  end

  private
    def recipients
      raise NotImplementedError
    end

    def creator
      source.creator
    end
end
```

**Specific notifiers:**

```ruby
# app/models/notifier/card_event_notifier.rb
class Notifier::CardEventNotifier < Notifier
  private
    def recipients
      case source.action
      when "card_assigned"
        source.particulars["assignee_ids"]
          &.map { |id| User.find(id) }
          &.reject { |u| u == creator }
      when "card_published", "card_commented"
        card.watchers.excluding(creator, *card.mentionees)
      else
        []
      end
    end

    def card
      source.eventable
    end
end
```

### Notification Bundling

Users can receive bundled notification emails:

```ruby
class Notification::Bundle
  def self.deliver_all
    User.wants_bundled_notifications.find_each do |user|
      deliver_for(user)
    end
  end

  def self.deliver_for(user)
    notifications = user.notifications.unread.bundleable

    if notifications.any?
      Notification::BundleMailer.digest(user, notifications).deliver_now
      notifications.update_all(bundled_at: Time.current)
    end
  end
end
```

### Webhook Integration

Events can trigger webhooks:

```ruby
class Webhook < ApplicationRecord
  belongs_to :account
  belongs_to :board, optional: true

  attribute :subscribed_actions, :json, default: []

  scope :triggered_by, ->(event) {
    where("subscribed_actions @> ?", [event.action].to_json)
  }

  def trigger(event)
    Webhook::DeliveryJob.perform_later(self, event)
  end
end
```

---

## 10. Mailers

### ApplicationMailer

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "Fizzy <support@fizzy.do>")
  layout "mailer"
  append_view_path Rails.root.join("app/views/mailers")

  helper AvatarsHelper, HtmlHelper

  private
    def default_url_options
      if Current.account
        super.merge(script_name: Current.account.slug)
      else
        super
      end
    end
end
```

### Mailer Pattern

```ruby
class MagicLinkMailer < ApplicationMailer
  def sign_in_instructions(magic_link)
    @magic_link = magic_link
    @identity = magic_link.identity

    mail(
      to: @identity.email_address,
      subject: "Your Fizzy code is #{@magic_link.code}"
    )
  end
end
```

### Triggering Emails

```ruby
# Immediate (in request)
MagicLinkMailer.sign_in_instructions(magic_link).deliver_now

# Background (recommended)
MagicLinkMailer.sign_in_instructions(magic_link).deliver_later

# From model callback
class Identity < ApplicationRecord
  def send_magic_link
    magic_links.create!.tap do |link|
      MagicLinkMailer.sign_in_instructions(link).deliver_later
    end
  end
end
```

---

## 11. Database & UUIDs

### UUID Primary Keys

All tables use UUIDv7 primary keys (time-sortable):

```ruby
# db/migrate/xxx_create_cards.rb
class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.references :board, type: :uuid, null: false, foreign_key: true
      t.string :title
      t.timestamps
    end
  end
end
```

### Custom UUID Type

**File:** `lib/rails_ext/active_record_uuid_type.rb`

```ruby
class ActiveRecord::Type::Uuid < ActiveRecord::Type::Binary
  BASE36_LENGTH = 25

  def self.generate
    uuid = SecureRandom.uuid_v7
    hex = uuid.delete("-")
    hex_to_base36(hex)
  end

  def self.hex_to_base36(hex)
    hex.to_i(16).to_s(36).rjust(BASE36_LENGTH, "0")
  end

  # Stored as binary(16) in MySQL, displayed as 25-char base36
end
```

### Benefits

- **Time-sortable**: Records created later have larger IDs
- **No collisions**: Globally unique without coordination
- **Compact**: 25 characters vs 36 for standard UUIDs
- **Index-friendly**: Binary storage with good locality

### Fixture UUIDs

Test fixtures get deterministic UUIDs that sort by fixture name:

```ruby
# test/test_helper.rb
module FixturesTestHelper
  def generate_fixture_uuid(label)
    # UUIDs based on fixture label, always older than runtime records
    fixture_int = Zlib.crc32("fixtures/#{label}")
    base_time = Time.utc(2024, 1, 1)
    timestamp = base_time + (fixture_int / 1000.0)
    uuid_v7_with_timestamp(timestamp, label)
  end
end
```

---

## 12. Full-Text Search

### Sharded Search

16-shard full-text search using MySQL (no Elasticsearch):

```ruby
# app/models/search/record.rb
class Search::Record < ApplicationRecord
  SHARD_COUNT = 16

  def self.shard_for(account)
    Zlib.crc32(account.id.to_s) % SHARD_COUNT
  end

  def self.table_name
    "search_records_#{Current.account ? shard_for(Current.account) : 0}"
  end
end
```

### Indexing

```ruby
# Via Searchable concern
module Searchable
  def index_for_search
    Search::Record.create!(
      account: account,
      card: self.is_a?(Card) ? self : card,
      board: board,
      searchable: self,
      title: searchable_title,
      content: searchable_content
    )
  end
end
```

### Querying

```ruby
class Search
  def initialize(query, account:)
    @query = query
    @account = account
  end

  def results
    Search::Record
      .where(account: @account)
      .where("MATCH(title, content) AGAINST(? IN BOOLEAN MODE)", @query)
      .includes(:card)
      .map(&:card)
      .uniq
  end
end
```

---

## 13. Testing Patterns

### Test Setup

**File:** `test/test_helper.rb`

```ruby
class ActiveSupport::TestCase
  parallelize workers: :number_of_processors

  fixtures :all

  include ActiveJob::TestHelper
  include SessionTestHelper, CardTestHelper, ChangeTestHelper

  setup do
    Current.account = accounts("37s")
  end

  teardown do
    Current.clear_all
  end
end

class ActionDispatch::IntegrationTest
  setup do
    # Set tenant context via script_name
    integration_session.default_url_options[:script_name] =
      "/#{ActiveRecord::FixtureSet.identify("37signals")}"
  end
end
```

### Controller Tests (Integration Tests)

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "index" do
    get cards_path
    assert_response :success
  end

  test "create a new draft" do
    assert_difference -> { Card.count }, 1 do
      post board_cards_path(boards(:writebook))
    end

    card = Card.last
    assert card.drafted?
    assert_redirected_to card_draft_path(card)
  end

  test "users can only see cards in boards they have access to" do
    get card_path(cards(:logo))
    assert_response :success

    boards(:writebook).update!(all_access: false)
    boards(:writebook).accesses.revoke_from(users(:kevin))

    get card_path(cards(:logo))
    assert_response :not_found
  end

  test "admins can delete any card" do
    assert_difference -> { Card.count }, -1 do
      delete card_path(cards(:logo))
    end
    assert_redirected_to boards(:writebook)
  end
end
```

### Model Tests (Unit Tests)

```ruby
class Card::AssignableTest < ActiveSupport::TestCase
  test "assigning a user makes them watch the card" do
    assert_not cards(:layout).assigned_to?(users(:kevin))
    cards(:layout).unwatch_by(users(:kevin))

    with_current_user(:jz) do
      cards(:layout).toggle_assignment(users(:kevin))
    end

    assert cards(:layout).assigned_to?(users(:kevin))
    assert cards(:layout).watched_by?(users(:kevin))
  end

  test "toggle_assignment respects assignment limit" do
    card = cards(:logo)
    card.assignments.delete_all

    Assignment::LIMIT.times do |i|
      user = create_user("limit_test_#{i}@example.com")
      card.assignments.create!(assignee: user, assigner: users(:david))
    end

    extra_user = create_user("over_limit@example.com")

    with_current_user(:david) do
      assert_no_difference "card.assignments.count" do
        card.toggle_assignment(extra_user)
      end
    end
  end
end
```

### Test Helpers

**File:** `test/test_helpers/session_test_helper.rb`

```ruby
module SessionTestHelper
  def sign_in_as(identity)
    cookies.delete(:session_token)

    identity = identities(identity) unless identity.is_a?(Identity)
    identity.send_magic_link
    magic_link = identity.magic_links.last

    untenanted do
      post session_path, params: { email_address: identity.email_address }
      post session_magic_link_url, params: { code: magic_link.code }
    end

    assert_response :redirect
  end

  def logout_and_sign_in_as(identity)
    Session.delete_all
    sign_in_as(identity)
  end

  def with_current_user(user)
    user = users(user) unless user.is_a?(User)
    old_session = Current.session
    Current.session = Session.new(identity: user.identity)
    yield
  ensure
    Current.session = old_session
  end

  def untenanted
    original = integration_session.default_url_options[:script_name]
    integration_session.default_url_options[:script_name] = ""
    yield
  ensure
    integration_session.default_url_options[:script_name] = original
  end
end
```

### Testing Jobs

```ruby
class MentionCreateJobTest < ActiveSupport::TestCase
  test "creates mentions for mentioned users" do
    card = cards(:logo)
    card.update!(description: "Hey @#{users(:kevin).email_address}")

    assert_difference -> { Mention.count }, 1 do
      perform_enqueued_jobs do
        Mention::CreateJob.perform_later(card, mentioner: users(:david))
      end
    end
  end
end
```

### Fixture Organization

```yaml
# test/fixtures/users.yml
david:
  account: 37s
  identity: david
  name: David
  role: owner
  email_address: david@example.com

kevin:
  account: 37s
  identity: kevin
  name: Kevin
  role: admin
  email_address: kevin@example.com

jz:
  account: 37s
  identity: jz
  name: JZ
  role: member
  email_address: jz@example.com
```

---

## 14. Configuration & Environment

### Environment Variables

```bash
# Database
DATABASE_URL=mysql2://user:pass@host/db

# Multi-tenancy
MULTI_TENANT=true

# Email
MAILER_FROM_ADDRESS="Fizzy <support@fizzy.do>"
SMTP_ADDRESS=smtp.mailgun.org
SMTP_USERNAME=...
SMTP_PASSWORD=...

# Storage
STORAGE_SERVICE=amazon  # or local

# Features
FIZZY_SAAS=true
```

### Configuration Module

**File:** `lib/fizzy.rb`

```ruby
module Fizzy
  def self.saas?
    ENV["FIZZY_SAAS"] == "true"
  end

  def self.version
    "1.0.0"
  end
end
```

### Initializers

Key initializers in `config/initializers/`:

| File | Purpose |
|------|---------|
| `tenanting/account_slug.rb` | Multi-tenancy middleware |
| `uuid_primary_keys.rb` | UUID type registration |
| `active_job.rb` | Job context capture |
| `multi_tenant.rb` | Tenant mode configuration |
| `content_security_policy.rb` | CSP headers |
| `sanitization.rb` | HTML sanitization rules |

### Database Configuration

**File:** `config/database.yml`

```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

---

## 15. Code Style & Conventions

### Method Ordering

From `STYLE.md`:

1. Class methods
2. Public methods (`initialize` first)
3. Private methods (in invocation order)

```ruby
class SomeClass
  def self.create_from(params)
    new(params).save
  end

  def initialize(params)
    @params = params
  end

  def save
    validate
    persist
  end

  private
    def validate
      validate_presence
      validate_format
    end

    def validate_presence
      # ...
    end

    def validate_format
      # ...
    end

    def persist
      # ...
    end
end
```

### Conditional Returns

Prefer expanded conditionals over guard clauses:

```ruby
# Preferred
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end

# Acceptable for early returns
def after_recorded_as_commit(recording)
  return if recording.parent.was_created?

  if recording.was_created?
    broadcast_new_column(recording)
  else
    broadcast_column_change(recording)
  end
end
```

### Private Method Indentation

```ruby
class SomeClass
  def public_method
    # ...
  end

  private
    def private_method_1
      # ...
    end

    def private_method_2
      # ...
    end
end
```

### CRUD Controllers

Model actions as resources:

```ruby
# Instead of custom actions
resources :cards do
  post :close    # Bad
  post :reopen   # Bad
end

# Model state as resources
resources :cards do
  resource :closure  # Good
end
```

### Async Method Naming

```ruby
# _later enqueues a job
def send_notification_later
  NotificationJob.perform_later(self)
end

# _now is synchronous
def send_notification_now
  # Actual notification logic
end
```

### No Bang for Destructive Actions

Only use `!` when there's a non-bang counterpart:

```ruby
save   # Returns boolean
save!  # Raises on failure

destroy  # No bang needed (no non-destructive version)
close    # No bang needed
```

---

## 16. Quick Reference

### Common Patterns

| Pattern | Usage |
|---------|-------|
| **Current context** | `Current.user`, `Current.account` |
| **State as resource** | `has_one :closure` + `closed?` |
| **Eventable** | `track_event(:action, particulars: {})` |
| **Searchable** | Include concern, implement `searchable_content` |
| **Async jobs** | `_later` enqueues, `_now` executes |

### Model Checklist

When creating a new model:

- [ ] Add `account_id` foreign key
- [ ] Include appropriate concerns
- [ ] Define scopes for common queries
- [ ] Add `preloaded` scope for eager loading
- [ ] Include `Eventable` if actions should be tracked
- [ ] Include `Searchable` if full-text indexed
- [ ] Add tests in `test/models/`

### Controller Checklist

When creating a new controller:

- [ ] Keep it thin - delegate to models
- [ ] Include appropriate concerns (`CardScoped`, etc.)
- [ ] Support multiple formats (HTML, Turbo, JSON)
- [ ] Add authorization checks
- [ ] Add tests in `test/controllers/`

### Job Checklist

When creating a new job:

- [ ] Keep it shallow - delegate to models
- [ ] Account context is automatic (via `FizzyActiveJobExtensions`)
- [ ] Use appropriate queue (`:backend`, `:webhooks`, `:mailers`)
- [ ] Add tests in `test/jobs/`

### Testing Commands

```bash
# Run all tests
bin/rails test

# Run specific file
bin/rails test test/models/card_test.rb

# Run specific test by line
bin/rails test test/models/card_test.rb:42

# Run system tests
bin/rails test:system

# Run full CI suite
bin/ci
```

### Useful Rake Tasks

```bash
# Database
bin/rails db:migrate
bin/rails db:reset
bin/rails db:fixtures:load

# Development
bin/dev                    # Start dev server
bin/rails dev:email        # Toggle email previews

# Jobs
bin/jobs                   # Solid Queue management
```

### File Naming

| Type | Convention | Example |
|------|------------|---------|
| Model | Singular | `card.rb` |
| Model concern | Module path | `card/assignable.rb` |
| Controller | Plural | `cards_controller.rb` |
| Nested controller | Directory | `cards/closures_controller.rb` |
| Job | Verb suffix | `create_job.rb` |
| Mailer | Present action | `magic_link_mailer.rb` |
| Test | `_test` suffix | `card_test.rb` |

---

## Appendix: Key Files Reference

### Models

| File | Purpose |
|------|---------|
| `app/models/current.rb` | Thread-local context |
| `app/models/account.rb` | Tenant model |
| `app/models/card.rb` | Main work item |
| `app/models/event.rb` | Audit trail |
| `app/models/notifier.rb` | Notification strategy |

### Controllers

| File | Purpose |
|------|---------|
| `app/controllers/application_controller.rb` | Base controller |
| `app/controllers/concerns/authentication.rb` | Auth logic |
| `app/controllers/concerns/card_scoped.rb` | Card context |

### Configuration

| File | Purpose |
|------|---------|
| `config/initializers/tenanting/` | Multi-tenancy |
| `config/recurring.yml` | Scheduled jobs |
| `config/queue.yml` | Solid Queue config |
| `lib/fizzy.rb` | App configuration |

### Tests

| Directory | Purpose |
|-----------|---------|
| `test/models/` | Unit tests |
| `test/controllers/` | Integration tests |
| `test/system/` | Browser tests |
| `test/test_helpers/` | Test utilities |

---

*This guide reflects the backend architecture in Fizzy. Keep it updated as patterns evolve.*
