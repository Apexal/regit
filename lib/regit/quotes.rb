module Regit
  module Quotes
    
    def self.add_quote(submitter, author, message)
      raise 'No message.' if message.empty? || message.nil?
      
      author ||= submitter

      # Make sure attributed author is a student
      student = Regit::Database::Student.find_by_discord_id(author.id)
      raise 'Attributed author is not a student!' if student.nil?

      message = Regit::Utilities::replace_mentions(message)
      LOGGER.info "Adding quote '#{message}' by #{author.distinct} | added by #{submitter.distinct}"
      quote = Regit::Database::Quote.create(username: submitter.info.username, author_username: author.info.username, text: message)
    end

    def self.delete_quote(id)
      quote = Regit::Database::Quote.find(id)
      quote.destroy
    end

  end
end