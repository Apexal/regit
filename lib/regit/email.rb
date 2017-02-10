module Regit
  module Email
    GMAIL = Gmail.connect!(Regit::CONFIG.gmail_username, Regit::CONFIG.gmail_password)
  end
end