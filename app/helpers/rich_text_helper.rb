module RichTextHelper
  def mentions_prompt
    content_tag "lexical-prompt", "", trigger: "@", src: prompts_users_path, name: "mention"
  end
end
