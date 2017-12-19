# Copyright (c) Ixia technologies 2015-2017, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create



namespace eval IxiaCapi {
    
    class BgpRouter {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
		public variable blockNameList
        constructor {} {
            set tag "body BgpRouter::ctor [info script]"
Deputs "----- TAG: $tag -----"
                                  
        }
        
        method ConfigRouter { args } {
            set tag "body BgpRouter::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
           
            eval ProtocolConvertObject::convert $args
			puts $objName 
			puts $newargs
            eval $objName config $newargs
			     
        }
        
        method CreateRouteBlock { args } {
            set tag "body BgpRouter::CreateRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
            eval ProtocolConvertObject::convert $args
			puts $objName 
			puts $newargs
					
            RouteBlock $blockname
			lappend blockNameList $blockname
			puts "blockNameList: $blockNameList"
			
            eval $blockname config $newargs
            eval $objName set_route -route_block  $blockname
			     
        }
        
        method ConfigRouteBlock { args } {
            set tag "body BgpRouter::ConfigRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
            eval ProtocolConvertObject::convert $args
			puts $objName 
			puts $newargs  			
            eval $blockname config $newargs
            eval $objName set_route -route_block $blockname
			     
        }
        
        method DeleteRouteBlock { args } {
            set tag "body BgpRouter::DeleteRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists blockname ] } {
                set index [ lsearch -exact $blockNameList $blockname ]
                if {$index >= 0 } {
                    $blockname unconfig
                    catch { uplevel " delete object $blockname " }
                    set blockNameList [ lreplace $blockNameList $index $index ]
                }
                
            
            } else {
                foreach blockItem $blockNameList {
                    $blockItem unconfig
                    catch { uplevel " delete object $blockItem " }
                } 
                set blockNameList ""
            }
        }
        
        method StartRouter {} {
            set tag "body BgpRouter::StartRouter [info script]"
Deputs "----- TAG: $tag -----"
            $objName start
            
        }
        method StopRouter {} {
            set tag "body BgpRouter::StopRouter [info script]"
Deputs "----- TAG: $tag -----"
            $objName stop
        }
        method AdvertiseRouteBlock { args } {
            set tag "body BgpRouter::AdvertiseRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists blockname ] } {
                $objName advertise_route -route_block $blockname
			} else {
			    $objName advertise_route
			}
        }
        method WithdrawRouteBlock { args } {
            set tag "body BgpRouter::WithdrawRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists blockname ] } {
               $objName withdraw_route -route_block $blockname
			} else {
			   $objName withdraw_route
			}
        }
       
        method GetRouterStats {} {
            set tag "body BgpRouter::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body BgpRouter::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            $objName get_detailed_stats
        }
        destructor {
            set tag "body BgpRouter::dtor [info script]"
Deputs "----- TAG: $tag -----"
            if {$blockNameList != ""} {
                foreach blockItem $blockNameList {
                    catch { uplevel " delete object $blockItem " }
                }
            }
        } 
        
      
    }
	
	class BgpV4Router {
	    inherit BgpRouter
        
        constructor { Port { routerId null } { hostname null } } {
            set tag "body BgpV4Router::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className BgpSession
            BgpSession ${this}_c  $Port
            if { $hostname != "null" } {
			   set intfhandle [ $hostname cget -interface]
			   ${this}_c config -hint $intfhandle
               
            } 
            if { $routerId != "null" } {
               ${this}_c config -router_id $routerId
            }
            
            
            set objName ${this}_c
            set argslist(-peertype)                  -type
            set argslist(-routerid)                  -router_id
            set argslist(-testerip)                  -ipv4_addr           
            set argslist(-testeras)                  -as
            set argslist(-sutip)                     -dut_ip
            set argslist(-sutas)                     -dut_as                                
			set argslist(-flagmd5)                    -flagmd5
            set argslist(-md5)                        -md5
            set argslist(-holdtimer)                  -hold_time_interval
            set argslist(-keepalivetimer)             -update_Interval              
            #set argslist(-connectretrytimer)                      
            #set argslist(-connectretrycount)              
            set argslist(-routesperupdate)            -max_routes_per_update
            #set argslist(-interupdatedelay)                 
            #set argslist(-flagendofrib)
            #set argslist(-flaglabelroutecapture)
            #set argslist(-startingLabel)             
            #set argslist(-endingLabel)   
            set argslist(-as_path)                    -as_path 			
            set argslist(-active)                     -active 
            set argslist(-addressfamily)              -address_family  
            set argslist(-firstroute)                 -start   
            set argslist(-routenum)                   -num  
            set argslist(-prefixlen)                  -prefix_len   
            set argslist(-modifer)                    -step  
            set argslist(-nexthop)                    -nexthop 
			set argslist(-origin)                     -origin
			set argslist(-med)                        -med
			set argslist(-local_pref)                 -local_pref
			set argslist(-cluster_list)               -cluster_list
			set argslist(-flagatomicaggregate)         -flag_atomic_agg
			set argslist(-aggregator_as)               -agg_as
			set argslist(-aggregator_ipaddress)        -agg_ip
			set argslist(-originator_id)               -originator_id
			set argslist(-communities)                 -communities
			#set argslist(-flaglabel)                    -flag_label
			#set argslist(-labelmode)                    -label_mode
			#set argslist(-userlabel)                    -user_label
			
			
			
           
           
        }
		
		
	}
	
	class BgpV6Router {
	    inherit BgpRouter
        
        constructor { Port { routerId null } { hostname null } } {
            set tag "body BgpV6Router::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className BgpSession
            BgpSession ${this}_c  $Port
            
            if { $hostname != "null" } {
			   set intfhandle [ $hostname cget -interface]
			   ${this}_c config -hint $intfhandle -ip_version ipv6
               
            } else {
               ${this}_c config -ip_version ipv6
            }
            
			
            
            if { $routerId != "null" } {
               ${this}_c config -router_id $routerId 
            }
            
            
            set objName ${this}_c
            set argslist(-peertype)                  -type
            set argslist(-routerid)                  -router_id
            set argslist(-testerip)                  -ipv6_addr           
            set argslist(-testeras)                  -as
            set argslist(-sutip)                     -dut_ip
            set argslist(-sutas)                     -dut_as                                
			set argslist(-flagmd5)                    -flagmd5  
            set argslist(-md5)                        -md5
            set argslist(-holdtimer)                  -hold_time_interval
            set argslist(-keepalivetimer)             -update_Interval              
            #set argslist(-connectretrytimer)                      
            #set argslist(-connectretrycount)              
            set argslist(-routesperupdate)            -max_routes_per_update
            #set argslist(-interupdatedelay)                 
            #set argslist(-flagendofrib)
            #set argslist(-flaglabelroutecapture)
            #set argslist(-startingLabel)             
            #set argslist(-endingLabel)   
            set argslist(-as_path)                    -as_path 			
            set argslist(-active)                     -active 
            set argslist(-addressfamily)              -address_family  
            set argslist(-firstroute)                 -start   
            set argslist(-routenum)                   -num  
            set argslist(-prefixlen)                  -prefix_len   
            set argslist(-modifer)                    -step  
            set argslist(-nexthop)                    -nexthop 
			set argslist(-origin)                     -origin
			set argslist(-med)                        -med
			set argslist(-local_pref)                 -local_pref
			set argslist(-cluster_list)               -cluster_list
			set argslist(-flagatomicaggregate)        -flag_atomic_agg
			set argslist(-aggregator_as)              -agg_as
			set argslist(-aggregator_ipaddress)       -agg_ip
			set argslist(-originator_id)              -originator_id
			set argslist(-communities)                -communities
			#set argslist(-flaglabel)                    -flag_label
			#set argslist(-labelmode)                    -label_mode
			#set argslist(-userlabel)                    -user_label
			
			
			
           
           
        }
		
		
	}
    
    
}