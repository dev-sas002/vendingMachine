shared_context 'request initializer' do
  subject { response }

  before do |example|
    next if example.metadata[:skip_request]

    # Some request specs are executed via rswag's `run_test!` and don't define
    # their own `request!` helper. Only auto-trigger when it exists.
    request! if respond_to?(:request!)
  end
end
