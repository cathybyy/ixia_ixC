# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1
#       1.modify CreateTopSummaryRouteBlock origin sameArea
#       2.modify CreateTopExternalRouteBlock origin externalType2
# Version 1.2
#       1. add deleteblock
#       2. add hostname in ctor

namespace eval IxiaCapi {
    
    class Ospfv2Router {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
        public variable blockList
        constructor { Port { routerId null } { hostname null } } {
            set tag "body Ospfv2Router::ctor [info script]"
Deputs "----- TAG: $tag -----"

            set className Ospfv2Session
            set blockList ""
            if { $hostname != "null" } {
			    set intfhandle [ $hostname cget -interface]
			    Ospfv2Session ${this}_c  $Port $intfhandle
              
            } else {
			    Ospfv2Session ${this}_c  $Port
			}
           
            if { $routerId != "null" } {
               ${this}_c config -terouter_id $routerId
            }
            
            
            set objName ${this}_c
			set argslist(-routerid)                -router_id
			set argslist(-macaddr)                  -mac_addr
			set argslist(-ipaddr)                 -ipv4_addr
			set argslist(-prefixlen)            -ipv4_prefix_len			
            set argslist(-area)                  -area_id
			set argslist(-sutipaddress)            -ipv4_gw
			set argslist(-sutprefixlen)            -ipv4_prefix_len			
            #set argslist(-sutrouterid)                  -areaid
			set argslist(-deadinterval)                  -dead_interval
			set argslist(-hellointerval)                -hello_interval
			
			set argslist(-networktype)               -network_type
			#set argslist(-routertype)                 -areaid2
            
            set argslist(-pduoptionvalue)              -options         
            #set argslist(-flaggre)            -level
			#set argslist(-polllinterval)                  -metric
			
			set argslist(-retranssmitinterval)         -retransmit_interval
			#set argslist(-transitdelay)       -FlagRestartHelper
			#set argslist(-maxlsasperpacket)          -FlagDropSutLsp
			set argslist(-interfacecost)     -if_cost
			set argslist(-routerpriority)           -priority
			#set argslist(-mtu)        -L2RouterPriority
			#set argslist(-flaghostroute)        -L1RouterPriority
			#set argslist(-restarreason)            -RoutingLevel
			#set argslist(-active)                -AuthType
			#set argslist(-authenticationtype)         -AuthPasswordIIh
			#set argslist(-password)            -AuthPassword
			#set argslist(-md5keyid)            -AuthPassword
			
          
           		
                                  
        }
        
        method ConfigRouter { args } {
            set tag "body Ospfv2Router::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
           
            eval ProtocolConvertObject::convert $args
			puts $objName 
			puts $newargs
            eval $objName config $newargs
			     
        }
        
        method CreateTopSummaryRouteBlock { args } {
            set tag "body Ospfv2Router::CreateTopSummaryRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            set prefixlen 16
			set number 1
			set modifier 1
            set origin "sameArea"
			
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-startingaddress {
					    set startingaddress $value
												
					}
					-prefixlen {
					    set prefixlen $value
												
					}
					-number {
					    set number $value
												
					}
					-modifier {
					    set modifier $value
												
					}
				}
			}
            
            RouteBlock $blockname
            lappend blockList $blockname
            eval $blockname config -start $startingaddress \
			    -step $modifier \
				-prefix_len $prefixlen \
				-num $number   \
                -origin  $origin
                
			
			#SimulatedSummaryRoute ${blockname}_s $objName
			#eval ${blockname}_s config -route_block $blockname
			
			     
        }
        
        method DeleteTopSummaryRouteBlock { args } {
            set tag "body Ospfv2Router::DeleteTopSummaryRouteBlock [info script]"
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
                set index [ lsearch -exact $blockList $blockname ]
                if {$index >= 0 } {
                    $blockname unconfig
                    catch { uplevel " delete object $blockname " }
                    set blockList [ lreplace $blockList $index $index ]
                }
                
            
            } else {
                foreach blockItem $blockList {
                    $blockItem unconfig
                    catch { uplevel " delete object $blockItem " }
                } 
                set blockList ""
            }
        }
        
        method ConfigRouteBlock { args } {
            set tag "body Ospfv2Router::ConfigRouteBlock [info script]"
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
            eval $blocknamename config $newargs
            eval $objName set_route -route_block $blockname
			     
        }
		
		method AddTopRouter { args } {
            set tag "body Ospfv2Router::AddTopRouter [info script]"
Deputs "----- TAG: $tag -----"
            set routertypevalue "normal"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-routername {
					    set routername [::IxiaCapi::NamespaceDefine $value]
												
					}
					-routerid {
					    set routerid $value
												
					}
					-routertypevalue {
					    set routertypevalue $value
												
					}
				}
			}
           SimulatedRouter $routername $objName
          
		   eval $routername config -id $routerid -type $routertypevalue
            
        }
		
		
		
		method CreateTopExternalRouteBlock { args } {
            set tag "body Ospfv2Router::CreateTopExternalRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            set prefixlen 16
			set number 1
			set modifier 1
            set origin "externalType2"
			
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-startingaddress {
					    set startingaddress $value
												
					}
					-prefixlen {
					    set prefixlen $value
												
					}
					-number {
					    set number $value
												
					}
					-modifier {
					    set modifier $value
												
					}
                    -type {
                        if {$value == "type_2"} {
                            set origin "externalType2"
                        } elseif { $value == "type_1" } {
                            set origin "externalType1"
                        }
                       
                    }
				}
			}
            
            RouteBlock $blockname
            lappend blockList $blockname
            eval $blockname config -start $startingaddress \
			    -step $modifier \
				-prefix_len $prefixlen \
				-num $number  \
                -origin $origin
				
			#SimulatedExternalRoute ${blockname}_s $objName
			#eval ${blockname}_s config -route_block $blockname
           
            
        }
        
        method DeleteTopExternalRouteBlock { args } {
            set tag "body Ospfv2Router::DeleteTopExternalRouteBlock [info script]"
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
                set index [ lsearch -exact $blockList $blockname ]
                if {$index >= 0 } {
                    $blockname unconfig
                    catch { uplevel " delete object $blockname " }
                    set blockList [ lreplace $blockList $index $index ]
                }
                
            
            } else {
                foreach blockItem $blockList {
                    $blockItem unconfig
                    catch { uplevel " delete object $blockItem " }
                } 
                set blockList ""
            }
        }
		
		method AddTopRouterLink { args } {
            set tag "body Ospfv2Router::AddTopRouterLink [info script]"
Deputs "----- TAG: $tag -----"
            set linkmetric 1

            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-routername {
					    set routername [::IxiaCapi::NamespaceDefine $value]
												
					}
					-linkname {
					    set linkname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-linkconnectedname {
					    set linkconnectedname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-linkmetric {
					    set linkmetric $value
												
					}
				}
			}
          
		   Deputs "routername:$routername"
		   SimulatedLink $linkname $objName
		   eval $linkname config -metric $linkmetric -route_block $linkconnectedname 
            
        }
        
        method StartRouter {} {
            set tag "body Ospfv2Router::StartRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start
            
        }
        method StopRouter {} {
            set tag "body Ospfv2Router::StopRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
        method AdvertiseLinks { args } {
            set tag "body Ospfv2Router::AdvertiseLinks [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-linknamelist {
					    set linknamelist [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists linknamelist ] } {
			    foreach link $linknamelist {
				    set hlink [$link cget -handle]
					ixNet setA $hlink -enabled True
				}
                ixNet commit
			} else {
			    eval $objName advertise_topo
			}
        }
        method WithdrawLinks { args } {
            set tag "body Ospfv2Router::WithdrawLinks [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-linknamelist {
					    set linknamelist [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists linknamelist ] } {
			    foreach link $linknamelist {
				    set hlink [$link cget -handle]
					ixNet setA $hlink -enabled False
				}
                ixNet commit
			} else {
			    eval $objName withdraw_topo
			}
        
        }
       
        method GetRouterStats {} {
            set tag "body Ospfv2Router::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body Ospfv2Router::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        destructor  {
            set tag "body Ospfv2Router::dtor [info script]"
Deputs "----- TAG: $tag -----"
            if {$blockList != ""} {
                foreach blockItem $blockList {
                    catch { uplevel " delete object $blockItem " }
                }
            }
        }
        
      
    }
    
    class Ospfv3Router {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
        public variable blockList
        constructor { Port { routerId null } { hostname null } } {
            set tag "body Ospfv3Router::ctor [info script]"
Deputs "----- TAG: $tag -----"

            set className Ospfv3Session
            set blockList ""
            if { $hostname != "null" } {
			    set intfhandle [ $hostname cget -interface]
			    Ospfv3Session ${this}_c  $Port $intfhandle
              
            } else {
			    Ospfv3Session ${this}_c  $Port
			}
            
            if { $routerId != "null" } {
               ${this}_c config -router_id $routerId
            }
            
            
            set objName ${this}_c
			set argslist(-routerid)                 -router_id
			set argslist(-macaddr)                  -mac_addr
			set argslist(-ipaddr)                   -ipv6_addr
			set argslist(-prefixlen)                -ipv6_prefix_len			
            set argslist(-area)                     -area_id
			set argslist(-networktype)              -network_type
			set argslist(-optionvalue)              -options
            set argslist(-sutipaddress)             -ipv6_gw
			#set argslist(-sutprefixlen)            -ipv6_prefix_len			
            #set argslist(-sutrouterid)             -areaid
            #set argslist(-flagneighbordr)          -L1RouterPriority
            set argslist(-hellointerval)            -hello_interval
			set argslist(-deadinterval)             -dead_interval
			#set argslist(-polllinterval)           -metric
            set argslist(-retranssmitinterval)      -retransmit_interval
            #set argslist(-transitdelay)            -FlagRestartHelper
			#set argslist(-maxlsasperpacket)        -FlagDropSutLsp
            set argslist(-interfacecost)            -if_cost
			set argslist(-routerpriority)           -priority
            #set argslist(-mtu)                     -L2RouterPriority
			#set argslist(-flaglsadiscardmode)      -L1RouterPriority           
            set argslist(-instanceid)                -instance_id 
            set argslist(-metric)                    -metric  			
            #set argslist(-internalmessageexchanger)   -level
			#set argslist(-active)                    -AuthType
			                                 
        }
        
        method ConfigRouter { args } {
            set tag "body Ospfv3Router::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
           
            eval ProtocolConvertObject::convert $args
			puts $objName 
			puts $newargs
            eval $objName config $newargs
			     
        }
        
        method CreateTopInterAreaPrefixRouteBlock { args } {
            set tag "body Ospfv3Router::CreateTopInterAreaPrefixRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            set prefixlen 80
			set number 1
			set modifier 1
			
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-startingaddress {
					    set startingaddress $value
												
					}
					-prefixlen {
					    set prefixlen $value
												
					}
					-number {
					    set number $value
												
					}
					-modifier {
					    set modifier $value
												
					}
				}
			}
            
            RouteBlock $blockname
            lappend blockList $blockname
            eval $blockname config -start $startingaddress \
			    -step $modifier \
				-prefix_len $prefixlen \
				-num $number
			SimulatedIntraAreaRoute ${blockname}_s $objName
			eval ${blockname}_s config -route_block $blockname
			     
        }
        
        method DeleteTopInterAreaPrefixRouteBlock { args } {
            set tag "body Ospfv2Router::DeleteTopInterAreaPrefixRouteBlock [info script]"
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
                set index [ lsearch -exact $blockList $blockname ]
                if {$index >= 0 } {
                    $blockname unconfig
                    catch { uplevel " delete object $blockname " }
                    set blockList [ lreplace $blockList $index $index ]
                }
                
            
            } else {
                foreach blockItem $blockList {
                    $blockItem unconfig
                    catch { uplevel " delete object $blockItem " }
                } 
                set blockList ""
            }
        }
        
        method ConfigRouteBlock { args } {
            set tag "body Ospfv3Router::ConfigRouteBlock [info script]"
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
            eval $blocknamename config $newargs
            eval $objName set_route -route_block $blockname
			     
        }
		
		method AddTopRouter { args } {
            set tag "body Ospfv2Router::AddTopRouter [info script]"
Deputs "----- TAG: $tag -----"
            set routertypevalue "normal"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-routername {
					    set routername [::IxiaCapi::NamespaceDefine $value]
												
					}
					-routerid {
					    set routerid $value
												
					}
					-routertypevalue {
					    set routertypevalue $value
												
					}
				}
			}
           SimulatedRouter $routername $objName
		   eval $routername config -id $routerid -type $routertypevalue
            
        }
		
		
		
		method CreateTopExternalPrefixRouteBlock { args } {
            set tag "body Ospfv3Router::CreateTopExternalPrefixRouteBlock [info script]"
Deputs "----- TAG: $tag -----"
            set prefixlen 80
			set number 1
			set modifier 1
			
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-blockname {
					    set blockname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-startingaddress {
					    set startingaddress $value
												
					}
					-prefixlen {
					    set prefixlen $value
												
					}
					-number {
					    set number $value
												
					}
					-modifier {
					    set modifier $value
												
					}
				}
			}
            
            RouteBlock $blockname
            lappend blockList $blockname
            eval $blockname config -start $startingaddress \
			    -step $modifier \
				-prefix_len $prefixlen \
				-num $number
				
			
			SimulatedExternalRoute ${blockname}_s $objName
			eval ${blockname}_s config -route_block $blockname
           
            
        }
        
        method DeleteTopExternalRouteBlock { args } {
            set tag "body Ospfv3Router::DeleteTopExternalRouteBlock [info script]"
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
                set index [ lsearch -exact $blockList $blockname ]
                if {$index >= 0 } {
                    $blockname unconfig
                    catch { uplevel " delete object $blockname " }
                    set blockList [ lreplace $blockList $index $index ]
                }
                
            
            } else {
                foreach blockItem $blockList {
                    $blockItem unconfig
                    catch { uplevel " delete object $blockItem " }
                } 
                set blockList ""
            }
        }
		
		method AddTopRouterLink { args } {
            set tag "body Ospfv3Router::AddTopRouterLink [info script]"
Deputs "----- TAG: $tag -----"
            set linkmetric 1

            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-linkname {
					    set linkname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-routername -
					-linkconnectedname {
					    set linkconnectedname [::IxiaCapi::NamespaceDefine $value]
												
					}
					-linkmetric {
					    set linkmetric $value
												
					}
				}
			}
           #SimulatedRouter $routername $this
		   #Deputs "routername:$routername"
		   SimulatedLink $linkname $objName
		   eval $linkname config -metric $linkmetric -route_block $linkconnectedname
            
        }
        
        method StartRouter {} {
            set tag "body Ospfv3Router::StartRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start
            
        }
        method StopRouter {} {
            set tag "body Ospfv3Router::StopRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
        method AdvertiseLinks { args } {
            set tag "body Ospfv3Router::AdvertiseLinks [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-linknamelist {
					    set linknamelist [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists linknamelist ] } {
			    foreach link $linknamelist {
				    set hlink [$link cget -handle]
					ixNet setA $hlink -enabled True
				}
                ixNet commit
			} else {
			    eval $objName advertise_topo
			}
        }
        method WithdrawLinks { args } {
            set tag "body Ospfv3Router::WithdrawLinks [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
				switch -exact -- $key {
					-linknamelist {
					    set linknamelist [::IxiaCapi::NamespaceDefine $value]
												
					}
				}
			}
			if { [info exists linknamelist ] } {
			    foreach link $linknamelist {
				    set hlink [$link cget -handle]
					ixNet setA $hlink -enabled False
				}
                ixNet commit
			} else {
			    eval $objName withdraw_topo
			}
        
        }
       
        method GetRouterStats {} {
            set tag "body Ospfv3Router::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body Ospfv3Router::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        destructor  {
            set tag "body Ospfv3Router::dtor [info script]"
Deputs "----- TAG: $tag -----"
            if {$blockList != ""} {
                foreach blockItem $blockList {
                    catch { uplevel " delete object $blockItem " }
                }
            }
        }
        
      
    }
    
    
	
	
    
    
}