module StripeMock
  @state = 'ready'
  @instance = nil
  @original_execute_request_method = Stripe::StripeClient.instance_method(:execute_request)

  def self.start
    return false if @state == 'live'

    @instance = instance = Instance.new
    # Monkey patch Stripe::StripeClient#execute_request to support ruby 3.0 kwargs
    Stripe::StripeClient.send(:define_method, :execute_request) do |*args, **kwargs|
      # Check if kwargs is empty and call mock_request accordingly
      if kwargs.empty?
        instance.mock_request(*args)
      else
        instance.mock_request(*args, **kwargs)
      end
    end

    @state = 'local'
  end

  def self.stop
    return unless @state == 'local'

    restore_stripe_execute_request_method
    @instance = nil
    @state = 'ready'
  end

  # Yield the given block between StripeMock.start and StripeMock.stop
  def self.mock(&block)
    begin
      self.start
      yield
    ensure
      self.stop
    end
  end

  def self.restore_stripe_execute_request_method
    Stripe::StripeClient.send(:define_method, :execute_request, @original_execute_request_method)
  end

  def self.instance; @instance; end
  def self.state; @state; end

end
