# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.14.58
#		2. Add ipv4_addr ipv4_gw ipv4_prefix_len ipv6_addr ipv6_gw ipv6_prefix_len in config
#		3. Add SimulatedRoute class
# Version 1.1.14.59
#       4. Add uncofig 2017.7.17

class IsisSession {
    inherit RouterEmulationObject
		
    constructor { port { hint null } } {}
    method reborn { {hint null } } {}
    method config { args } {}
	method set_route { args } {}
	method advertise_route { args } {}
	method withdraw_route { args } {}
	method unconfig {} {
	    set tag "body IsisSession::unconfig [info script]"
		Deputs "----- TAG: $tag -----"		
		catch {
		    
			set ptemp [ixNet getL $hPort/protocols/isis router]
			Deputs "$ptemp"
			if {[llength $ptemp] == 1 } {
			    set temphandle $hPort
			    chain
			    Deputs "disable $temphandle isis protocol"
				ixNet setA $temphandle/protocols/isis -enabled false
				ixNet commit
			} else {
			    chain
			}
		}
						
	}
	
	method start {} {
	    set tag "body IsisSession::start [info script]"
    Deputs "----- TAG: $tag -----"
	    ixNet exec start $hPort/protocols/isis
	}
	method stop {} {
	    set tag "body IsisSession::stop [info script]"
    Deputs "----- TAG: $tag -----"
	    ixNet exec stop $hPort/protocols/isis
	}

	public variable mac_addr
	public variable routeBlock
}

body IsisSession::reborn { {hint null } } {
    set tag "body IsisSession::reborn [info script]"
    Deputs "----- TAG: $tag -----"
	#-- add isis protocol
Deputs "hPort:$hPort"
	set handle [ ixNet add $hPort/protocols/isis router ]
	ixNet setA $handle -name $this
	ixNet commit
	set handle [ ixNet remapIds $handle ]
Deputs "handle:$handle"

	#-- add router interface
	if { $hint == "null" } {
		set intList [ ixNet getL $hPort interface ]
		if { [ llength $intList ] } {
			set interface [ lindex $intList 0 ]
		} else {
			set interface [ ixNet add $hPort interface ]
			ixNet setA $interface -enabled True
			ixNet commit
			set interface [ ixNet remapIds $interface ]
		Deputs "port interface:$interface"
		}
		ixNet setA $hPort/protocols/isis -enabled True
		ixNet setA $handle -enabled True
		ixNet commit
		#-- add vlan
		set vlan [ ixNet add $interface vlan ]
		ixNet commit
		
		#-- port/protocols/isis/router/interface
		set rb_interface  [ ixNet add $handle interface ]
		ixNet setM $rb_interface \
			-interfaceId $interface \
			-enableConnectedToDut True \
			-enabled True
		ixNet commit
		set rb_interface [ ixNet remapIds $rb_interface ]
	} else {
	    ixNet setA $hPort/protocols/isis -enabled True
		ixNet setA $handle -enabled True
		set interface $hint
		ixNet commit
		set rb_interface  [ ixNet add $handle interface ]
		ixNet setM $rb_interface \
			-interfaceId $hint \
			-enableConnectedToDut True \
			-enabled True
		ixNet commit
		set rb_interface [ ixNet remapIds $rb_interface ]
	}
Deputs "rb_interface:$rb_interface"    
}

body IsisSession::constructor { port { hint null }} {
    set tag "body IsisSession::constructor [info script]"
    Deputs "----- TAG: $tag -----"
	
    global errNumber
    
    #-- enable protocol
    set portObj [ GetObject $port ]
Deputs "port:$portObj"
    if { [ catch {
	    set hPort   [ $portObj cget -handle ]
Deputs "port handle: $hPort"
    } ] } {
	    error "$errNumber(1) Port Object in IsisSession ctor"
    }
Deputs "initial port..."
Deputs "hint: $hint"
    if { $hint != "null" } {
	    reborn $hint
	} else {
	    reborn
	}
Deputs "Step10"
}

body IsisSession::config { args } {
    set tag "body IsisSession::config [info script]"
Deputs "----- TAG: $tag -----"
	
	#set sys_id "64:01:00:01:00:00"
# in case the handle was removed
    if { $handle == "" } {
	    reborn
    }
	
    Deputs "Args:$args "
    foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-sys_id - 
			-system_id {
				set sys_id $value
			}
			-areaid {
				set areaid $value
			}
			-areaid1 {
				set areaid1 $value
			}
			-areaid2 {
				set areaid2 $value
			}
			-terouter_id {
				set terouter_id $value
			}
			-network_type {
				set value [string tolower $value]
					switch $value {
					p2p {
						set value pointToPoint
					}
					p2mp {
						set value pointToMultipoint
					}
					default {
						set value broadcast
					}
				}
				set network_type $value
			}
            -discard_lsp {
            	set discard_lsp $value
            }
            -interface_metric -
            -metric {
            	set metric $value
            }
            -hello_interval {
            	set hello_interval $value  	    	
            }
            -dead_interval {
            	set dead_interval $value  	    	
            }
            -vlan_id {
            	set vlan_id $value
            }
            -lsp_refreshtime {
            	set lsp_refreshtime $value
            }
            -lsp_lifetime {
            	set lsp_lifetime $value
            }
			-mac_addr {
                set value [ MacTrans $value ]
                if { [ IsMacAddress $value ] } {
                    set mac_addr $value
                } else {
Deputs "wrong mac addr: $value"
                    error "$errNumber(1) key:$key value:$value"
                }
				
			}
			-ipv6_addr {
				set ipv6_addr $value
			}
			-ipv6_gw {
				set ipv6_gw $value
			}
			-ipv6_prefix_len {
				set ipv6_prefix_len $value
			}
			-ip_version {
				set ip_version $value
			}
			-level {
				set level $value
			}
            -l2routerpriority {
				set l2routerpriority $value
			}
            -l1routerpriority {
				set l1routerpriority $value
			}
			-flagwidemetric {
				set flagwidemetric $value
			}
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_prefix_len {
				set ipv4_prefix_len $value
			}
			-ipv4_gw {
                if {[IsIPv4Address $value]} {
                    set ipv4_gw $value
                } elseif {[IsIPv6Address $value]} {
                    set ipv6_gw $value
                }
				
			}
		}
    }
	
	if { [ info exists ip_version ] } {
		if { [ string tolower $ip_version ] == "ipv6" } {
			if { [ llength [ ixNet getL $interface ipv4 ] ] } {
				ixNet remove [ ixNet getL $interface ipv4 ]
				ixNet commit
			}
		} else {
			if { ![ llength [ ixNet getL $interface ipv4 ] ] } {
				ixNet add $interface ipv4
				ixNet commit
			}
		}
	}
	
	if { [ info exists ipv4_addr ] } {
		ixNet setA [ ixNet getL $interface ipv4 ] \
		-ip $ipv4_addr
	}
	
	if { [ info exists ipv4_prefix_len ] } {
		ixNet setA [ ixNet getL $interface ipv4 ] \
		-maskWidth $ipv4_prefix_len
	}
	
	if { [ info exists ipv4_gw ] } {
		ixNet setA [ ixNet getL $interface ipv4 ] \
		-gateway $ipv4_gw
	}
	
	if { [ info exists ipv6_addr ] } {
		ixNet setA [ ixNet getL $interface ipv6 ] \
		-ip $ipv6_addr
	}
	
	if { [ info exists ipv6_prefix_len ] } {
		ixNet setA [ ixNet getL $interface ipv6 ] \
		-prefixLength $ipv6_prefix_len
	}
	
	if { [ info exists ipv6_gw ] } {
		ixNet setA [ ixNet getL $interface ipv6 ] \
		-gateway $ipv6_gw
	}
	
	if { [ info exists level ] } {
		switch [ string tolower $level ] {
			l1 {
				set level level1
				ixNet setA $handle -enableAttached false 
			}
			l2 {
				set level level2
			}
			l12 {
				set level level1Level2
				ixNet setA $handle -enableAttached false 
			}
			l1l2 -
			{l1/l2} {
				set level level1Level2
				ixNet setA $handle -enableAttached false 
			}
		}
		ixNet setA $rb_interface -level $level
	}
    if { [ info exists l2routerpriority ] } {
	    ixNet setA $rb_interface -priorityLevel2 $l2routerpriority
    }
    if { [ info exists l1routerpriority ] } {
	    ixNet setA $rb_interface -priorityLevel1 $l1routerpriority
    }
	
    if { [ info exists sys_id ] } {
		while { [ ixNet getF $hPort/protocols/isis router -systemId "[ split $sys_id : ]"  ] != "" } {
Deputs "sys_id: $sys_id"		
			set sys_id [ IncrMacAddr $sys_id "00:00:00:00:00:01" ]
		}
Deputs "sys_id: $sys_id"		
	    ixNet setA $handle -systemId $sys_id
    }
    if { [ info exists network_type ] } {
	    ixNet setA $rb_interface -networkType $network_type
    }
    if { [ info exists discard_lsp ] } {
    	ixNet setA $handle -enableDiscardLearnedLsps $discard_lsp
    }
    if { [ info exists metric ] } {
	    ixNet setA $rb_interface -metric $metric
    }
    if { [ info exists hello_interval ] } {
	    ixNet setA $rb_interface -level1HelloTime $hello_interval
    }
    if { [ info exists dead_interval ] } {
	    ixNet setA $rb_interface -level1DeadTime $dead_interval
    }
    if { [ info exists vlan_id ] } {
	    set vlan [ixNet getL $interface vlan]
	    ixNet setA $vlan -vlanId $vlan_id
    }
    if { [ info exists lsp_refreshtime ] } {
    	ixNet setA $handle -lspRefreshRate $lsp_refreshtime
    }
    if { [ info exists lsp_lifetime ] } {
    	ixNet setA $handle -lspLifeTime $lsp_lifetime
    }
	if { [ info exists terouter_id ] } {
    	ixNet setM $handle -teEnable true \
			-teRouterId $terouter_id
    }
	if { [ info exists areaid ] } {
	    if { [ info exists areaid1 ] } {
		    if { [ info exists areaid2 ] } {
			    ixNet setA $handle -areaAddressList [list $areaid $areaid1 $areaid2]    
			} else {
			    ixNet setA $handle -areaAddressList [list $areaid $areaid1 ]
			}
		} else {
		    ixNet setA $handle -areaAddressList [list $areaid ]
		}			
    }
	if { [ info exists flagwidemetric ] } {
	    ixNet setA $handle -enableWideMetric $flagwidemetric
		ixNet commit
    }

	if { [ info exists mac_addr ] } {
Deputs "interface:$interface mac_addr:$mac_addr"
		ixNet setA $interface/ethernet -macAddress $mac_addr
	}
    ixNet commit
	return [GetStandardReturnHeader]

}

body IsisSession::set_route { args } {

    global errorInfo
    global errNumber
    set tag "body IsisSession::set_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
	
		foreach rb $route_block {
			set num 		[ $rb cget -num ]
			set step 		[ $rb cget -step ]
			set prefix_len 	[ $rb cget -prefix_len ]
			set start 		[ $rb cget -start ]
			set type 		[ $rb cget -type ]
            set origin 		[ $rb cget -origin ]            
           
			
			set hRouteBlock [ ixNet add $handle routeRange ]
			ixNet commit
			set hRouteBlock [ ixNet remapIds $hRouteBlock ]
			set routeBlock($rb,handle) $hRouteBlock
			lappend routeBlock(obj) $rb
						
			if {$origin != "" } { 
                ixNet setA $hRouteBlock \
                    -origin $origin  
                ixNet commit
            }	
            ixNet setM $hRouteBlock \
                -type $type  \
				-numberOfRoutes $num \
				-firstRoute $start \
				-maskWidth $prefix_len  \
                -metric 1
				
			ixNet commit
            


            ixNet setA $hRouteBlock \
              -numberOfRoutes $num
            ixNet commit

            
            

			$rb configure -handle $hRouteBlock
			$rb configure -portObj $portObj
			$rb configure -hPort $hPort
			$rb configure -protocol "isis"
			$rb enable
		}
	}
	
    return [GetStandardReturnHeader]
	

}

class SimulatedRoute {
	inherit SimulatedSummaryRoute
	
	constructor { router } { chain $router } {}
	method config { args } {}

}

body SimulatedRoute::config { args } {

	global errorInfo
    global errNumber
    set tag "body SimulatedRoute::config [info script]"
Deputs "----- TAG: $tag -----"

	eval chain $args

	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            
			-route_type {
				set route_type $value
			}
        }
    }
	
	if { [ info exists $route_type ] } {
		if { [ string to lower $route_type ] == "internal" } {
			set route_origin false
		} else {
			set route_origin true
		}
		ixNet setA $handle -routeOrigin $route_origin
	}
	
	ixNet commit
}

body IsisSession::advertise_route { args } {
    global errorInfo
    global errNumber
    set tag "body IsisSession::advertise_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
		ixNet setA $routeBlock($route_block,handle) \
			-enabled True
	} else {
		foreach hRouteBlock $routeBlock(obj) {
Deputs "hRouteBlock : $hRouteBlock"		
			ixNet setA $routeBlock($hRouteBlock,handle) -enabled True
		}
	}
	ixNet commit
	return [GetStandardReturnHeader]

}

body IsisSession::withdraw_route { args } {
    global errorInfo
    global errNumber
    set tag "body IsisSession::withdraw_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
		ixNet setA $routeBlock($route_block,handle) \
			-enabled False
	} else {
		foreach hRouteBlock $routeBlock(obj) {
			ixNet setA $routeBlock($hRouteBlock,handle) -enabled False
		}
	}
	ixNet commit
	return [GetStandardReturnHeader]

}