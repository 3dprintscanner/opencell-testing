# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!


ActionMailer::Base.smtp_settings = {
    :user_name => 'opencell.bio',
    :password =>  Rails.application.credentials.dig(:sendgrid_password),
    :domain => 'lims-dev.sudo.bio',
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
}
