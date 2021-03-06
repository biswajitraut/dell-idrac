require 'rexml/document'
require 'uri'
require '/etc/puppetlabs/puppet/modules/asm_lib/lib/security/encode'

include REXML

class Puppet::Provider::Checkjdstatus <  Puppet::Provider
  def initialize (ip,username,password,instanceid)
    @ip = ip
    @username = username
    @password = password
	@password = URI.decode(asm_decrypt(@password))
    @instanceid = instanceid
  end

  def checkjdstatus
    #Get the job status
    #response = `wsman get "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LifecycleJob?InstanceID=#{@instanceid}" -h #{@ip} -V -v -c dummy.cert -P 443 -u #{@username} -p #{@password} -j utf-8 -y basic`
	  response = executecmd 
    Puppet.info "#{response}"
    xmldoc = Document.new(response)
    jdnode = XPath.first(xmldoc, "//n1:JobStatus")
    jdmsg = XPath.first(xmldoc, "//n1:Message")
    tempjdnode = jdnode
    if jdmsg.to_s =~ /Staged component configuration is complete/i
      return "Completed"
    end
    if jdmsg.to_s =~ /Completed with Errors/i || jdmsg.to_s =~ /Completed with errors/i
      return "Failed"
    end
    
    if tempjdnode.to_s == ""
      raise "Job ID not created"
    end
    jdstatus=jdnode.text
    return jdstatus
  end

  def executecmd 
    resp = `wsman get "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LifecycleJob?InstanceID=#{@instanceid}" -h #{@ip} -V -v -c dummy.cert -P 443 -u #{@username} -p #{@password} -j utf-8 -y basic`
    return resp
  end
end

