require File.expand_path('../../libraries/models/lbaas/loadbalancer_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/listener_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/pool_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/member_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/health_monitor_model', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../libraries/network_manager', __FILE__)
require File.expand_path('../../libraries/utils', __FILE__)
require File.expand_path('../../../barbican/libraries/barbican_utils', __FILE__)
require File.expand_path('../../../barbican/libraries/secret_manager', __FILE__)
#-------------------------------------------------------
lb_attributes = node[:workorder][:rfcCi][:ciAttributes]
cloud_name = node[:workorder][:cloud][:ciName]
service_lb_attributes = node[:workorder][:services][:slb][cloud_name][:ciAttributes]
tenant = TenantModel.new(service_lb_attributes[:endpoint],service_lb_attributes[:tenant],
                         service_lb_attributes[:username],service_lb_attributes[:password])
stickiness = lb_attributes[:stickiness]
persistence_type = lb_attributes[:persistence_type]

subnet_id = select_provider_network_to_use(tenant, service_lb_attributes[:enabled_networks])

barbican_container_name = get_barbican_container_name()
connection_limit = (lb_attributes[:connection_limit]).to_i
Chef::Log.info("connection_limit : #{connection_limit}")

include_recipe "octavia::build_lb_name"
lb_name = node[:lb_name]
listeners = Array.new
#loadbalancers array contains a list of listeners from lb::build_load_balancers
node.loadbalancers.each do |loadbalancer|
  vprotocol = loadbalancer[:vprotocol]
  vport = loadbalancer[:vport]
  iprotocol = loadbalancer[:iprotocol]
  iport = loadbalancer[:iport]
  sg_name = loadbalancer[:sg_name]

  if vprotocol == 'HTTPS' and iprotocol == 'HTTPS'
    health_monitor = initialize_health_monitor('TCP', lb_attributes[:ecv_map], lb_name, iport)
  else
    health_monitor = initialize_health_monitor(iprotocol, lb_attributes[:ecv_map], lb_name, iport)
  end

  members = initialize_members(subnet_id, iport)
  pool = initialize_pool(iprotocol, lb_attributes[:lbmethod], lb_name, members, health_monitor, stickiness, persistence_type)
  if !barbican_container_name.nil? && !barbican_container_name.empty? && vprotocol == 'TERMINATED_HTTPS'
    secret_manager = SecretManager.new(service_lb_attributes[:endpoint], service_lb_attributes[:username],service_lb_attributes[:password], service_lb_attributes[:tenant] )
    container_ref = secret_manager.get_container(barbican_container_name)
    Chef::Log.info("Container_ref : #{container_ref}")
    listeners.push(initialize_listener(vprotocol, vport, lb_name, pool, connection_limit, container_ref))
  else
    listeners.push(initialize_listener(vprotocol, vport, lb_name, pool, connection_limit))
  end

end
loadbalancer = initialize_loadbalancer(subnet_id, service_lb_attributes[:provider], lb_name, listeners)

lb_manager = LoadbalancerManager.new(tenant)
Chef::Log.info("Creating Loadbalancer ..." + lb_name)
start_time = Time.now
Chef::Log.info("start time " + start_time.to_s)
loadbalancer_id = lb_manager.create_loadbalancer(loadbalancer)
Chef::Log.info("end time " + Time.now.to_s)
total_time = Time.now - start_time
Chef::Log.info("Total time to create " + total_time.to_s)

lb = lb_manager.get_loadbalancer(loadbalancer_id)
node.set[:lb_dns_name] = lb.vip_address
Chef::Log.info("VIP Address: " + lb.vip_address.to_s)

vnames = get_dc_lb_names()
vnames[lb_name] = nil
vnames.keys.each do |key|
  vnames[key] = lb.vip_address
end

Chef::Log.info("Exiting octavia-lbaas add recipe.")

puts "***RESULT:vnames=" + vnames.to_json
