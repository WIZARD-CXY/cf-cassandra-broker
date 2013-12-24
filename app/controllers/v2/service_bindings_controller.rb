class V2::ServiceBindingsController < V2::BaseController
  def update
    instance = ServiceInstance.find(params.fetch(:service_instance_id))
    #logger.info "INSTANCE IS #{instance.inspect}"
    binding = ServiceBinding.new(params.fetch(:id),instance)
    binding.save

    render status: 201, json: binding
  end

  def destroy
    instance = ServiceInstance.find(params.fetch(:service_instance_id))
    if binding = ServiceBinding.find_by_id(params.fetch(:id),instance)
      binding.destroy
      status = 204
    else
      status = 410
    end

    render status: status, json: {}
  end
end
