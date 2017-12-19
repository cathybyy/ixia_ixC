# Copyright (c) Ixia technologies 2015-2017, Inc.
# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1
#       1. add  Class MldRouter


namespace eval IxiaCapi {
    
    class MLDHost {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
		public variable groupName
        constructor { Port { hostname null } } {
            set tag "body MLDHost::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className MldHost
			if { $hostname != "null" } {
			    set inttype [$hostname cget -topStack]
			    set intfhandle [ $hostname cget -topHandle]
				puts $intfhandle
Deputs "-----intfhandle: $intfhandle -----"
                MldHost ${this}_c  $Port $intfhandle $inttype
			} else {
			    MldHost ${this}_c  $Port 
			}
            
            
            set objName ${this}_c
            
            set argslist(-active)                       -active
            set argslist(-protocoltype)                  -version
            set argslist(-sendgrouprate)                -rate
           
            set argslist(-v1routerpresenttimeout)       -v1_router_present_timeout
            set argslist(-forcerobustjoin)              -force_robust_join
            set argslist(-unsolicitedreportinterval)    -unsolicited_report_interval
            set argslist(-insertchecksumerrors)         -insert_checksum_errors 
            set argslist(-insertlengtherrors)           -insert_length_errors
           
			set argslist(-grouppoolname)                    -group_name
            set argslist(-groupcnt)                         -group_num  
            set argslist(-srcstartip)                       -source_ip
            set argslist(-filtermode)                       -filter_mode
            set argslist(-startip)                          -group_ip 
            			
        
        }
        
        method ConfigRouter { args } {
            set tag "body MLDHost::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
            eval $objName config $newargs
        
        }
        
        method Enable {} {
            set tag "body MLDHost::Enable [info script]"
Deputs "----- TAG: $tag -----"
           
            eval $objName enable
            
        }
        method Disable {} {
            set tag "body MLDHost::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName disable
        }
        method CreateGroupPool { args } {
            set tag "body MLDHost::CreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        method ConfigGroupPool { args } {
            set tag "body MLDHost::ConfigGroupPool [info script]"
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
				set groupName $gName
			}
            eval $gName config $newargs
			
			eval $objName join_group -group $groupName 
        }
        method DeleteGroupPool { args } {
            set tag "body MLDHost::DeleteGroupPool [info script]"
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
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }
			
            if {[ info exists grouppoolname ]} {
                eval $objName join_group $grouppoolname
			} else {
			    eval $objName join_group
			}
            
        }
        method SendLeave { args } {
            set tag "body MLDHost::SendLeave [info script]"
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
                eval $objName leave_group $grouppoolname
			} else {
			    eval $objName send_leave
			}

           
        }
        method ResendReport {} {
            set tag "body MLDHost::ResendReport [info script]"
Deputs "----- TAG: $tag -----"
            SendReport
        }
        method GetRouterStats {} {
            set tag "body MLDHost::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
        destructor {}
        
    
    }
    
    
    class MLDRouter {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
		public variable groupName
        constructor { Port { hostname null } } {
            set tag "body MLDRouter::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className MldRouter
			if { $hostname != "null" } {
			    set inttype [$hostname cget -topStack]
			    set intfhandle [ $hostname cget -topHandle]
				puts $intfhandle
Deputs "-----intfhandle: $intfhandle -----"
                MldQuery ${this}_c  $Port $intfhandle $inttype
			} else {
			    MldQuery ${this}_c  $Port 
			}
            
            
            set objName ${this}_c
            
            set argslist(-active)                       -active
            set argslist(-protocoltype)                 -version
           
            set argslist(-lastmemberquerycount)         -startup_query_count
            set argslist(-queryinterval)                -general_query_interval
            set argslist(-queryresponseuperbound)       -gq_response_interval
          
           
			set argslist(-grouppoolname)                    -group_name
            set argslist(-groupcnt)                         -group_num  
            set argslist(-srcstartip)                       -source_ip
            set argslist(-filtermode)                       -filter_mode
            set argslist(-startip)                          -group_ip 
            			
        
        }
        
        method ConfigRouter { args } {
            set tag "body MLDRouter::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
            eval $objName config $newargs
        
        }
        
        method Enable {} {
            set tag "body MLDRouter::Enable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName config -active enabled
            
        }
        method Disable {} {
            set tag "body MLDRouter::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName config -active disabled
        }
        method CreateGroupPool { args } {
            set tag "body MLDRouter::CreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        method ConfigGroupPool { args } {
            set tag "body MLDRouter::ConfigGroupPool [info script]"
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
				set groupName $gName
			}
            eval $gName config $newargs
			
			eval $objName join_group -group $groupName 
        }
        method DeleteGroupPool { args } {
            set tag "body MLDRouter::DeleteGroupPool [info script]"
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
			
			foreach poolname $grouppoolname {
			    set index [lsearch $groupName $poolname]
				if { $index >= 0} {
				   lreplace $groupName $index $index
				}
 			}
        }
     
        method StartGeneralQuery { args } {
            set tag "body MLDRouter::StartGeneralQuery [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start

           
        }
        method StopGeneralQuery {} {
            set tag "body MLDRouter::StopGeneralQuery [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
        
        method GetRouterStats {} {
            set tag "body MLDHost::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
        
        destructor {}
        
    
    }
}