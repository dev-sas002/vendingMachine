namespace :swagger do
  desc 'Regenerate swagger/v1/swagger.yaml, capturing real response bodies'
  task generate: :environment do
    # rswag defaults to a dry run, which produces a document with schemas but
    # no examples. Issuing the requests for real means every documented
    # response carries a body that the suite actually produced.
    ENV['SWAGGER_DRY_RUN'] = '0'

    Rake::Task['rswag:specs:swaggerize'].invoke
  end
end
