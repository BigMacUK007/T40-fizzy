module RichTextHelper
  def mentions_prompt
    content_tag "lexical-prompt", "", trigger: "@", src: prompts_users_path, name: "mention"
  end

  def cards_prompt
    content_tag "lexical-prompt", "", trigger: "#", src: prompts_cards_path, name: "card", "insert-editable-text": true, "remote-filtering": true
  end
end
