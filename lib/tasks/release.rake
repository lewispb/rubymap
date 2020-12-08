task release: :environment do
  sh "bundle exec rails db:migrate"
  sh "bundle exec rails db:seed"
end