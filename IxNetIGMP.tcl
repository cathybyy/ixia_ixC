# Copyright (c) Ixia technologies 2015-2017, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create

namespace eval IxiaCapi {
    
    class IGMPClient {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
		public variable hostName
        public variable className
		public variable groupName
        constructor { Port { hostname null }  } {
            set tag "body IGMPClient::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className IgmpHost
			set groupName ""
			set hostName ""
			if { $hostname != "null" } {
			    set inttype [$hostname cget -topStack]
			    set intfhandle [ $hostname cget -topHandle]
				puts $intfhandle
				set hostName $hostname
Deputs "-----intfhandle: $intfhandle -----"
                IgmpHost ${this}_c  $Port $intfhandle $inttype
			} else {
			    IgmpHost ${this}_c  $Port 
			}
            
            
            
            set objName ${this}_c
            
            set argslist(-protocoltype)                  -version
            set argslist(-sendgrouprate)                -rate
            set argslist(-active)                       -active
            set argslist(-v1routerpresenttimeout)       -v1_router_present_timeout
            set argslist(-forcerobustjoin)              -force_robust_join
            set argslist(-unsolicitedreportinterval)    -unsolicited_report_interval
            set argslist(-insertchecksumerrors)         -insert_checksum_errors 
            set argslist(-insertlengtherrors)           -insert_length_errors
            set argslist(-ipv4dontfragment)             -ipv4_dont_fragment
			
			set argslist(-localmac)                        -macaddr
			set argslist(-srcmac)                        -macaddr
		
			set argslist(-localmacmodifier)                -sourcemacmodifier
			set argslist(-vlanid1)                         -vlanid1
			set argslist(-vlanid)                         -vlanid1
			set argslist(-qinqlist)                        -qinqlist
			set argslist(-vlanpriority1)                   -outer_vlan_priority
			set argslist(-ipv4addr)                     -ipv4addr
            set argslist(-ipv4addrgateway)              -ipv4gatewayaddr
            set argslist(-ipv4addrprefixlen)            -ipv4mask
            
            
            set argslist(-grouppoolname)                    -group_name
            set argslist(-groupcnt)                         -group_num  
            set argslist(-srcstartip)                       -source_ip
            set argslist(-filtermode)                       -filter_mode
            set argslist(-startip)                          -group_ip
			set argslist(-groupincrement)                   -group_step
            set argslist(-srcincrement)                     -source_step			
            
        }
        
        method ConfigRouter { args } {
            set tag "body IGMPClient::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
			if { $hostName != "" } {
			    eval $hostName NewConfig $newargs
			}
            eval $objName config $newargs
            #eval $objName join_group $newargs
        
        }
        
        method Enable {} {
            set tag "body IGMPClient::Enable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start
            
        }
        method Disable {} {
            set tag "body IGMPClient::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
        
        method CreateGroupPool { args } {
            set tag "body IGMPClient::CreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        
        method ConfigGroupPool { args } {
            set tag "body IGMPClient::ConfigGroupPool [info script]"
Deputs "----- TAG: $tag -----"
           eval ProtocolConvertObject::convert $args
           foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoolname {
                        set gName $value
                    }
                }
            }
			if { [GetObject $gName ] == "" } {
			
				uplevel #0 "MulticastGroup $gName" 
				lappend groupName $gName
			}
			eval $gName config $newargs
			
			#eval $objName join_group -group $gName 

            
        }
		
		method DeleteGroupPool { args } {
            set tag "body IGMPClient::DeleteGroupPool [info script]"
Deputs "----- TAG: $tag -----"
			foreach { key value } $args {
				set key [string tolower $key]
				switch -exact -- $key {
                    -grouppoolname -
					-grouppoollist {
						set grouppoolname $value
					}
				}
			}
			
		
            
            if { [info exists grouppoolname ] } {
                foreach poolname $grouppoolname {
                    set index [lsearch $groupName $poolname]
                    if { $index >= 0} {
                       $poolname unconfig
                       catch { uplevel " delete object $poolname " }
                       set groupName [lreplace $groupName $index $index]
                    }
                }
                               
            
            } else {
                foreach poolname $groupName {
                    $poolname unconfig
                    catch { uplevel " delete object $poolname " }
                } 
                set groupName ""
            }
           
        }
        
        method SendReport { args } {
            set tag "body IGMPClient::SendReport [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }
			
           
            if {[ info exists grouppoolname ]} {
                Deputs "gouppoolname:$grouppoolname"
                #eval $objName join_group -group $grouppoolname
				$objName join_group -group $grouppoolname
			} else {
			    eval $objName join_group -group $groupName
			}
        }
        method SendLeave { args} {
            set tag "body IGMPClient::SendLeave [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }

            if {[ info exists grouppoolname ]} {
                #eval $objName leave_group -group $grouppoolname
				$objName leave_group -group $grouppoolname
			} else {
			    eval $objName leave_group -group $groupName
			}
        }
		
		method SendArpRequest {args } {
		     set tag "body IGMPClient::SendArpRequest [info script]"
Deputs "----- TAG: $tag -----"
             $hostName SendArpRequest $args
		}
       
        method GetRouterStats {} {
            set tag "body DHCPv6Client::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body DHCPv6Client::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
        destructor {}
        
      
    }
    
   
}