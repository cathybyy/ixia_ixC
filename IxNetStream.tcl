# Stream.tcl --
#   This file implements the Stream class for the highlevel CAPI of IxNetwork device.
#
# Copyright (c) Ixia technologies, Inc.

# Change made
# Version 1.1
# Version 1.2 add port self to the default receive port  2016.5.25
# merge with N55 version 2016.3.8
# Version 1.3 modify addpdu, custom header split into custom and ethernet
# Version 1.3 modify addpdu, igmpv2 header modify ipv4 totallength 28
# Version 1.3 modify addpdu, igmpv3 multicastsource



namespace eval IxiaCapi {
    
    class Stream {
        
        constructor { portHandle portname  args } {}
        method constructor_old { portHandle portname  args } {}
        method Config { args } {}
		method AddPduOld { args } {}
        method AddPdu { args } {}
        method ConfigField { pro args } {}
        method ClearPdu {} {}
        method DestroyPdu { args } {}
        method GetProtocolTemp { pro } {}
        method GetField { stack field } {}
        method SetProfileParam {} {}
        method SetSrcMac { mac } {
		    set srcMac $mac
		}
		method SetDstMac { mac } {
		    set dstMac $mac
		}
		method SetSrcIpv4 { ip } {
		    set srcIpv4 $ip
		}
		method SetDstIpv4 { ip } {
		    set dstIpv4 $ip
		}
		method SetSrcIpv6 { ip } {
		    set srcIpv6 $ip
		}
		method SetDstIpv6 { ip } {
		    set dstIpv6 $ip
		}
        method SetFlowFlag { value } {
		    set flowflag $value
		}
		method SetPortObj { portname } {
		    set PortObj $portname
			puts "PortObj: $PortObj"
		}
		method SetNoSignature {} {
		Deputs "body Stream::SetNoSignature"
		    set  trackingflag 0
			
		}
        destructor {}
                
        public variable hStream
		public variable hFlow
        public variable hPort
		public variable hTrafficItem
        public variable ProfileName
        public variable endPoint
		public variable PortObj
        
        public variable stackLevel
        private variable PduList
        public variable statsIndex
        public variable flagCommit
		public variable trackingflag
        public variable srcMac
        public variable dstMac
		public variable srcIpv4
        public variable dstIpv4
		public variable srcIpv6
        public variable dstIpv6
        public variable flowflag
    }
    
    
    class Pdu {
        constructor { pduPro { pduType "APP" } } {
            set EMode [ list Incrementing Decremeting Fixed Random ]
            set fieldModes [ list ]
            set fields [ list ]
            set fieldConfigs [ list ]
            set optionals [ list ]
            set autos [ list ]
            set valid 0
            set type $pduType
            set protocol $pduPro
Deputs "type:$type\tprotocol:$protocol"
            return $this
        }
        method ConfigPdu { args } {}
        destructor {}
        public variable protocol
        # SET - set | APP - append | MOD - modify | RAW - raw data
        public variable type
        public variable fields
        public variable fieldModes
        public variable fieldConfigs
        public variable optionals
        public variable autos
        public variable raw
        private variable valid
        method ChangeType { chtype } { set type $chtype }
        method SetProtocol { value } { set protocol $value }
        method SetRaw { value } { set raw $value }
        method AddField { value { optional 0 } { auto 0 } } {
            lappend fields $value
            lappend optionals $optional
            lappend autos $auto
            set valid 1
Deputs "fields:$fields optionals:$optionals autos:$autos"
        }
        # Fixed | List | Segment ( set a segment of bits from the beginning of certain field )
        # | Incrementing | Decrementing | Reserved ( for option and auto now )
        method AddFieldMode { value } {
            lappend fieldModes $value
            set valid 1
        }
        method AddFieldConfig { args } {
            lappend fieldConfigs $args
            set valid 1
        }
        method Clear {} {
            set fields [ list ]
            set fieldModes [ list ]
            set fieldConfigs [ list ]
            set optionals [ list ]
            set valid 0
        }
        method IsValid {} {
            return $valid
        }
    }
    

    
    
    body Stream::constructor { port portname  args } {
        global errorInfo IxiaCapi::true IxiaCapi::false
        set tag "body Stream::Ctor [info script]"
        set hPort   $port
        set hStream ""
        set srcMac ""
        set dstMac ""
		set srcIpv4 ""
        set dstIpv4 ""
		set srcIpv6 ""
        set dstIpv6 ""
        set stackLevel 1
        set flagCommit 1
		set enable_sig		0   
		set trackingflag 1
        set profileName "null"
        set flowflag 0
		set PortObj $portname
		set frameLen $IxiaCapi::DefaultFrameLen
Deputs "----- TAG: $tag -----"
        Deputs "Args:$args "
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -profile -
                -profilename {
                    set profileName $value
                }
                -dstpoolname {
                    set dst $value
                }
                -srcpoolname {
                    set src $value
                }  
                -streamtype {
                    set trafficType $value
                } 
                -flowflag {
                    set flowflag $value
                }
                -handle {
                    set handle $value
                }
                -insertsignature {
				    if { $value == "false" } {					   
                        set trackingflag 0
					}
                }                
            }
        }
        if { ( $profileName == "vpn" ) || ( $profileName == "device" ) } {
#AgtDebugOn
Deputs "vpn or device invoking..."
#AgtDebugOff
            return
        }
        set vport $port
Deputs "vport:$vport"
        if { [ catch {
# Create stream at an undefined profile    
            if { $profileName == "null" } {
			Deputs "profileName is null"
                set profileName [TrafficManager GetProfileByIndex 0]
				Deputs "profileName :trafficmanager get $profileName"
            }
			if { $profileName != "" } {
				set ProfileName $profileName
				Deputs "profileName : $profileName"
				set proObj [ IxiaCapi::Regexer::GetObject $ProfileName ]
				Deputs "proObj:$proObj"
				$proObj AddStreamGroup $this   
            }			
            
            set root [ixNet getRoot]
            set newAdd 0
            if { $flowflag } {
                set traObj [uplevel "$PortObj cget -Traffic"]
                set streamList [ $traObj GetStreamList ]
                if { $streamList != "" } {
                    set handle [[lindex $streamList 0] cget -hTrafficItem]
                } else {
                    set handle [ixNet add $root/traffic trafficItem]
                    ixNet setA $root/traffic/statistics/l1Rates -enabled True
                    ixNet setA $root/traffic \
                            -enableDataIntegrityCheck False \
                            -enableMinFrameSize True
                    ixNet commit
                    set newAdd 1
                }
                
               
            } else {
                set handle [ixNet add $root/traffic trafficItem]
                ixNet setM $handle \
                -name $this
                ixNet commit
                  
                ixNet setA $root/traffic/statistics/l1Rates -enabled True
                ixNet setA $root/traffic \
                        -enableDataIntegrityCheck False \
                        -enableMinFrameSize True
                ixNet commit
            }
            

            if { [ info exists src ] && [ info exists dst ] } {
                                       
                set bidirection 0
                set fullMesh 0
                set selfdst 0
                set tos_tracking 0
                set no_src_dst_mesh 0
                set no_mesh 0
                set to_raw 0
                set pdu_index 1
				set enable_sig 1
                
                set srcHandle [ list ]
        Deputs "src list:$src"		
                foreach srcEndpoint $src {
        # Deputs "src:$srcEndpoint"
                    set srcObj [ GetObject $srcEndpoint ]
        # Deputs "srcObj:$srcObj"			
                    if { $srcObj == "" } {
                    Deputs "illegal object...$srcObj"
                        set srcObj $portObj
                    # error "$errNumber(1) key:src value:$src (Not an object)"                
                    }
                    
                   if { [ $srcObj isa RouteBlock ] } {
        Deputs "route block:$srcObj"
                        if { [ $srcObj cget -protocol ] == "bgp" } {
                            set routeBlockHandle [ $srcObj cget -handle ]
                            set hBgp [ ixNet getP $routeBlockHandle ]
        Deputs "bgp route block:$hBgp"
                            if { [ catch {
                                set rangeCnt [ llength [ ixNet getL $hBgp routeRange ] ]
                            } ] } {
                                set rangeCnt [ llength [ ixNet getL $hBgp vpnRouteRange ] ]
                            }
                            if { $rangeCnt > 1 } {
                                set p [ ixNet getP $routeBlockHandle ]
                                set startIndex [ string first $p $routeBlockHandle ]
                                set endIndex [ expr $startIndex + [ string length $p ] - 1 ]
                                set routeBlockHandle \
                                [ string replace $routeBlockHandle \
                                $startIndex $endIndex $p.0 ]
            Deputs "route block handle:$routeBlockHandle"		
                            } else {
                                set routeBlockHandle [ $srcObj cget -hPort ]/protocols/bgp
                            }
                            set srcHandle [ concat $srcHandle $routeBlockHandle ]
                        } else {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                        }
                        #set trafficType [ $srcObj cget -type ]
                    } elseif { [ $srcObj isa IxiaCapi::PoolNameObject ] } {
					    set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
					} elseif { [ $srcObj isa IxiaCapi::Host ] } {
					    set topstack [$srcObj cget -topStack ]
						puts "topstack: $topstack"
					    if { $topstack == "802DOT1X"} {
						     set trafficType "ethernetVlan"
						}
                        
                        #set trafficType [ $srcObj cget -UpperLayer ]
                        if {$trafficType == "ipv4"} {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topv4Handle ] ]
                        } elseif { $trafficType == "ipv6" } {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topv6Handle ] ]
                        } else {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topHandle ] ]
                        }
                    } elseif { [ $srcObj isa MulticastGroup ] } {
                        if { [ $srcObj cget -protocol ] == "mld" } {
                            set trafficType "ipv6"
                        } 
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    } elseif { [ $srcObj isa VcLsp ]   } {
                        set trafficType "ethernetVlan"
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    } else {
                    Deputs Step120
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    }
                }
        Deputs "src handle:$srcHandle"

                set dstHandle [ list ]
        Deputs "dst list:$dst"		
                foreach dstEndpoint $dst {
        # Deputs "dst:$dstEndpoint"
                    set dstObj [ GetObject $dstEndpoint ]
        # Deputs "dstObj:$dstObj"			
                    if { $dstObj == "" } {
                    Deputs "illegal object...$dstEndpoint"
                     error " key:dst value:$dst"                
                    }
                   
                 
                    if { [ $dstObj isa RouteBlock ] } {
                        if { [ $dstObj cget -protocol ] == "bgp" } {
                            set routeBlockHandle [ $dstObj cget -handle ]
                            set hBgp [ ixNet getP $routeBlockHandle ]
        Deputs "bgp route block:$hBgp"
                            if { [ catch {
                                set rangeCnt [ llength [ ixNet getL $hBgp routeRange ] ]
                            } ] } {
                                set rangeCnt [ llength [ ixNet getL $hBgp vpnRouteRange ] ]
                            }
                            if { $rangeCnt > 1 } {
                                set p [ ixNet getP $routeBlockHandle ]
                                set startIndex [ string first $p $routeBlockHandle ]
                                set endIndex [ expr $startIndex + [ string length $p ] - 1 ]
                                set routeBlockHandle \
                                [ string replace $routeBlockHandle \
                                $startIndex $endIndex $p.0 ]
            Deputs "route block handle:$routeBlockHandle"		
                            } else {
                                set routeBlockHandle [ $dstObj cget -hPort ]/protocols/bgp
                            }
                            set dstHandle [ concat $dstHandle $routeBlockHandle ]
                        } else {
        Deputs "dst obj:$dstObj"				
        Deputs "route block handle:[$dstObj cget -handle]"				
                            set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                        }
                    } elseif { [ $dstObj isa IxiaCapi::PoolNameObject ] } {
					    set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
					} elseif { [ $dstObj isa IxiaCapi::Host ] } {
                       Deputs " $dstObj isa Host"
                        if {$trafficType == "ipv4"} {
                            #set dstHandle [ concat $srcHandle [ $dstObj cget -topv4Handle ] ]
                            set dstHandle [ $dstObj cget -topv4Handle ] 
                        } elseif { $trafficType == "ipv6" } {
                           # set dstHandle [ concat $srcHandle [ $dstObj cget -topv6Handle ] ]
                            set dstHandle [ $dstObj cget -topv6Handle ] 
							Deputs "dstHandle : $dstHandle"
                        } else {
                            #set dstHandle [ concat $srcHandle [ $dstObj cget -topHandle ] ]
                             set dstHandle [ $dstObj cget -topHandle ] 
                        }
                    } elseif { [ $dstObj isa MulticastGroup ] } {
                        set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                    } else {
                        set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                    }
                }
        #-- advanced stream Ports/Emulations
        Deputs "Traffic type: advanced stream:$trafficType"
                  #-- Create advanced stream
                  #-- create trafficItem      
                if { $bidirection } {
                    set bi True
                } else {
                    set bi False
                }
                if { $selfdst } {
                    set sd True
                } else {
                    set sd False
                }
                if { $fullMesh } {
                    Deputs "traffic src/dst type: full mesh"		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -routeMesh oneToOne \
                         -srcDestMesh fullMesh \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan

                } else {
                    if { $no_mesh } {
        Deputs "traffic src/dst type: none"		  		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -biDirectional $bi \
                         -routeMesh oneToOne \
                         -srcDestMesh none \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan
                    } else {
        Deputs "traffic src/dst type: one 2 one"		  		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -biDirectional $bi \
                         -routeMesh oneToOne \
                         -srcDestMesh oneToOne \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan
                    }
                }
                if { $enable_sig } {
				Deputs "aaaaaaaaaaaaa:add tracking"
                    ixNet setA $handle/tracking -trackBy sourceDestPortPair0
                    #ixNet setA $handle/tracking -trackBy trackingenabled0
                    ixNet commit
                }
        Deputs "add endpointSet..."
                ixNet commit
                #-- add endpointSet
                set endpointSet [ixNet add $handle endpointSet]
                if { $srcHandle == "" || $dstHandle == "" } {
                   IxiaCapi::Logger::LogIn -type err -message \
                   "endpointSet element is empty, please check protocol is up " -tag $tag
                   return $IxiaCapi::errorcode(1)
                }
        Deputs "src:$srcHandle"
                ixNet setA $endpointSet -sources $srcHandle
        Deputs "dst:$dstHandle"
                ixNet setA $endpointSet -destinations $dstHandle
                  
                ixNet commit
                set handle      [ ixNet remapIds $handle ]
        Deputs "handle:$handle"
       
                ixNet commit
            } else {                             
                set endPoint [ixNet add $handle endpointSet]
            Deputs "port:$hPort"
                set dests [list]
                set root [ixNet getRoot]
                foreach port [ ixNet getList $root vport ] {
				#add self port to default receive list
            # Deputs "dest port:$port"
                    # if { $port == $hPort } {
                        # continue
                    # }
            # Deputs "lappend dests..."
                   lappend dests "$port/protocols"
                }
            Deputs "dests: $dests"
            # IxDebugOff
                if { [ llength $dests ] == 0 } {
                
                    ixNet setMultiA $endPoint -sources "$hPort/protocols" -destinations "$hPort/protocols"
                } else {
                
                    ixNet setMultiA $endPoint -sources "$hPort/protocols" -destinations $dests
                }
           
                ixNet commit
          
                set handle      [ ixNet remapIds $handle ]
          
                set endPoint [ ixNet remapIds $endPoint ]
                
                if { $flowflag == 0 || $newAdd == 1 } {
                    if { $enable_sig } {   
Deputs "aaaaabbbbbaaa:add tracking"	
                        if { $newAdd == 1 }	{
                            ixNet setA $handle/tracking -trackBy [list flowGroup0 sourceDestPortPair0]
                        } else {
                            ixNet setA $handle/tracking -trackBy sourceDestPortPair0 
                        }		
                     
                       
                        ixNet commit
				   }
                }  
                
             
                
            }
            
			
        } result ] } {
            IxiaCapi::Logger::LogIn -type exception -message "$errorInfo" -tag $tag
        } else {
            set hFlow [ lindex [ ixNet getList $handle highLevelStream ] end ]
            if { $flowflag == 1 } {
                ixNet setA $hFlow -name $this
                ixNet commit
                    
            } 
			
			set hStream [lindex [ ixNet getList $handle configElement ] end]
			puts "hStream: $hStream"
			ixNet setA $hStream/frameSize -fixedSize $frameLen
			ixNet commit
			ixNet setA $hFlow/frameSize -fixedSize $frameLen
			ixNet commit
			if { $profileName != "" } {
				$proObj RefreshStreamLoad
				IxiaCapi::Logger::LogIn -message "$IxiaCapi::s_StreamCtor2 \n\t\
				Profile name: $ProfileName"
			}
        }
        
		set hTrafficItem $handle
        if { $flowflag == 1 } {
            Flow ${this}_flow $PortObj $hFlow $hTrafficItem
            
        } else {
            Traffic ${this}_item $PortObj $hTrafficItem  
        }
	
		return $this
    }
    
    body Stream::AddPduOld { args } {
        global IxiaCapi::fail IxiaCapi::success IxiaCapi::true IxiaCapi::false
        global errorInfo
        
        set tag "body Stream::AddPdu [info script]"
Deputs "----- TAG: $tag -----"
Deputs "args: $args"
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -name -
                -names -
                -pduname {
                    set nameList $value
					#set nameList [::IxiaCapi::NamespaceDefine $value]
                }
            }
        }
        
        if { [ info exists nameList ] == 0 } {
            IxiaCapi::Logger::LogIn -type err -message "$IxiaCapi::s_common1 \
            $IxiaCapi::s_StreamAddPdu2" -tag $tag
                        return $IxiaCapi::errorcode(3)                        
        } else {
Deputs "name list: $nameList"
        }

        set err 0
        set index 0
		set fgindex 0
#add for modify multi vlan and mpls header
		set vlannum 0
		set mplsnum 0
		#set trackingflag 1
        foreach name $nameList {
# Read type protocol message

            if { [ catch {

                set protocol [ uplevel 1 " $name cget -protocol " ]
Deputs "Pro: $protocol "

                set type [ string toupper [ uplevel 1 " $name cget -type " ] ]
				
				if { [regexp .*(igmp).+  $protocol] } {
				Deputs "Header is igmp type, no flow tracking"
				    set trackingflag 0
				}
                set stackList [ ixNet getList $hStream stack ]
                if { ( $protocol == "custom" ) && ( $fgindex == 0 )&&([llength $stackList]== 2) } {
                    set type SET
					
                }
Deputs "Type $type "
            } ] } {
#Deputs "Objects:[find obj]"
                IxiaCapi::Logger::LogIn -type err -message "$IxiaCapi::s_common1 \
                $IxiaCapi::s_StreamAddPdu1 $name" -tag $tag
                set err 1
                continue
            } else {
                set proStack [ GetProtocolTemp $protocol ]
Deputs "protocol stack: $proStack"
            }
# Set or Append pdu protocols
            if { [ catch {

                set stack  [ lindex [ ixNet getList $hStream stack ] 0 ]
#Deputs "type:$type"
                set needMod 1
                switch -exact -- $type {
                    SET {
#Deputs "stream:$hStream"
                        set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list:$stackList"
                        while { 1 } {
                            set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list after removal:$stackList"
                            if { [ llength $stackList ] == 2 } {
                                break
                            }
                            ixNet exec remove [ lindex $stackList [ expr [ llength $stackList ] - 2  ] ]
                        }
#Deputs "Stack ready to add:$stackList"
                        ixNet exec append [ lindex $stackList 0 ] $proStack
                        ixNet exec remove [ lindex $stackList 0 ]
                        set stack  [ lindex [ ixNet getList $hStream stack ] 0 ]
                        set stackLevel 1
                    }
                    APP {
#Deputs "stream:$hStream"
                        set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list:$stackList"
                        set appendHeader [ lindex $stackList [expr $stackLevel - 1] ]
#Deputs "appendHeader:$appendHeader"
#Deputs "stack to be added: $proStack"
                        ixNet exec append $appendHeader $proStack
                        set stack [lindex [ ixNet getList $hStream stack ] $stackLevel]
#Deputs "stack:$stack"
                        incr stackLevel
#Deputs "stackLevel:$stackLevel"
                        #set stack ${hStream}/stack:\"[ string tolower $protocol ]-${stackLevel}\"
                    }
                    MOD {
                        set index 0
                        set findflag 0
						if { $protocol == "Vlan" } {
						    set findflag [expr 0 - $vlannum]
						    incr vlannum 1
							
							
						}
						if { $protocol == "MPLS" } {
						    set findflag [expr 0 - $mplsnum]
						    incr mplsnum 1
						  
						}
#Deputs "protocol:$protocol"
                        foreach pro [ ixNet getList $hStream stack ] {
#Deputs "pro:$pro"
                            if { [ regexp -nocase $protocol $pro ] } {
                                if { [ regexp -nocase "${pro}\[a-z\]+" $stack ] == 0 } {
                                   incr findflag 1
									if { $findflag == 1 } {
									    break
									}
                                }
                            }
                            incr index
                        }
                        Deputs "findflag: $findflag"
						if { $findflag != 1 } {
						    set stackList [ ixNet getList $hStream stack ]
							Deputs "stackList: $stackList"
							
						    switch -exact -- $name {
							    ::::IxiaCapi::pdul2_1 -
								:::IxiaCapi::pdul2_1 -
								::IxiaCapi::pdul2_1 {
									set MstackLevel 1									
								}
                                ::::IxiaCapi::pdul4 -
                                :::IxiaCapi::pdul4 -								
								::IxiaCapi::pdul4 {
								Deputs "add L4 header"
									set MstackLevel [expr [llength $stackList] - 1]
								Deputs "MstackLevel:$MstackLevel"
									
								}	
							}
							
#Deputs "Stack list:$stackList"
                            set appendHeader [ lindex $stackList [expr $MstackLevel - 1] ]
#Deputs "appendHeader:$appendHeader"
#Deputs "stack to be added: $proStack"
                            ixNet exec append $appendHeader $proStack
                            set stack [lindex [ ixNet getList $hStream stack ] $MstackLevel]
							incr MstackLevel
#Deputs "stack:$stack"
                            
						} else {
						    set stack $pro
						}
                    }
                    default { }
                }
                ixNet commit
                catch {
                    set stack [ ixNet remapIds $stack ]
                }
#Deputs "Stack:$stack"
                set appendHeader $stack
#Deputs "Stack list:[ ixNet getList $hStream stack ]"
            } ] } {

                IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
#Deputs "error occured..."
                set err 1
                continue
            }
            if { $needMod == 0 } {

                incr index
                continue
            }
# Modify fields
            if { [ catch {
			    if {$protocol == "custom"} {
				    set raw [ uplevel 1 " $name cget -raw " ]
	#Deputs "raw: $raw"
					set raw [ List2Str $raw ]
	#Deputs "raw: $raw"
					#set customStack [ lindex [ ixNet getList $hStream stack ] 0 ]
					set customStack $stack
	#Deputs "customStack:$customStack"
					set fieldList [ ixNet getList $customStack field ]
	#Deputs "fieldList: $fieldList"
					set rawLen [expr [string length $raw] * 4]
	#Deputs "rawLen:$rawLen"
					ixNet setA [ lindex $fieldList 0 ] -singleValue $rawLen
					
					ixNet commit
				    if { [ regexp -nocase {^0x} $raw ] } {
	
					    ixNet setA [ lindex $fieldList 1 ] -singleValue $raw
				    } else {
	
					    ixNet setA [ lindex $fieldList 1 ] -singleValue 0x$raw
				    }
					ixNet commit
					
					
				} else {

                    set fieldModes [ uplevel 1 " $name cget -fieldModes " ]
                    set fields [ uplevel 1 " $name cget -fields " ]
                    set fieldConfigs [ uplevel 1 " $name cget -fieldConfigs " ]
                    set optional [ uplevel 1 " $name cget -optionals " ]
                    set autos [ uplevel 1 " $name cget -autos " ]
#Deputs "name list len: [llength $nameList]"
                    if { [ lsearch -exact $fields "etherType" ] < 0 } {
                        if { [ llength $nameList ] == 1 } {

#Deputs "protocol:$protocol"
                            if { [ string tolower $protocol ] == "ethernet" } {

                                lappend fieldModes Fixed
                                lappend fields     etherType
                                lappend fieldConfigs 0x88b5
                                lappend autos       0
                                lappend optional    0
                            }
                        } else {
                            if { [ string tolower $protocol ] == "ethernet" } {

                                lappend fieldModes Reservedf
                                lappend fields     etherType
                                lappend fieldConfigs 0
                                lappend autos       1
                                lappend optional    0
                            }
                        }
                    }
Deputs "PDU:\n\tModes:$fieldModes\n\tFields:$fields\n\tConfigs:$fieldConfigs\n\tOptional:$optional\n\tAutos:$autos"
                    foreach mode $fieldModes field $fields conf $fieldConfigs\
                        opt $optional auto $autos {
#Deputs "stack:$stack"
#Deputs "field:$field"
                        set obj [ GetField $stack $field ]
#Deputs "Field object: $obj"

                        if { [ info exists opt ] } {
                            if { $opt == "" } { continue }
                            if { $opt } {
							    ixNet setA $obj -activeFieldChoice True
								 
                                ixNet setA $obj -optionalEnabled True
                                continue
                            }
                        } else {
                            continue
                        }
                        if { [ info exists auto ] } {

                            if { $auto == "" } { continue }

                            if { $auto } {

                                ixNet setA $obj -auto True
                                continue
                            } else {
                            
                                ixNet setA $obj -auto False
                            }
                        } else {
                            continue
                        }
                        if { [ info exists mode ] == 0 || [ info exists field ] == 0 ||\
                            [ info exists conf ] == 0 } {
#Deputs "continue"
                            continue
                        }
Deputs "Mode:$mode"
                        switch -exact $mode {
                            Fixed {
#Deputs "Fixed:$protocol\t$field\t$conf"
                                ixNet setMultiAttrs $obj \
                                -valueType singleValue \
                                -singleValue $conf
                            }
                            List {
#Deputs "List:$protocol\t$field\t$conf"
                                ixNet setMultiAttrs $obj \
                                -valueType valueList
                                -valueList $conf
                            }
                            Segment {
#                            set offset [ AgtInvoke AgtPduHeader GetFieldBitOffset \
#                                $hPdu $protocol 1 $field ]
#Deputs "Offset: $offset"
#                            AgtInvoke AgtRawPdu SetPduBytes $hPdu \
#                                [ expr $offset / 8 ] [ string length $conf ] $conf
                            }
                            Reserved {
#Deputs "Reserved...continue"
                                continue
                            }
                            Incrementing -
                            Decrementing {
                                set mode [string range $mode 0 8]
                                set mode [string tolower $mode]
Deputs "Mode:$mode\tProtocol:$protocol\tConfig:$conf"
                                set start [lindex $conf 1]
                                set count [lindex $conf 2]
                                set step  [lindex $conf 3]
#Deputs "obj:$obj mode: $mode start:$start count:$count step:$step"
                                ixNet setMultiAttrs $obj \
                                -valueType $mode \
                                -countValue $count \
                                -stepValue $step \
                                -startValue $start
                            }
                            Commit {
                                ixNet setMultiAttrs $obj \
                                -valueType singleValue \
                                -singleValue $conf
                                ixNet commit
                            }
                        }
						ixNet commit
                    }
                }
		    }] } {

                IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
Deputs "error occured..."
                set err 1
                IxiaCapi::Logger::LogIn -type warn -message \
                "$IxiaCapi::s_StreamAddPdu3 $name" -tag $tag
                continue
            } else {
                IxiaCapi::Logger::LogIn -message "$IxiaCapi::s_StreamAddPdu4 $name"
            }
            incr index
			incr fgindex
        }

        if { [ catch {

            ixNet commit
        } ] } {
            IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
                    return $IxiaCapi::errorcode(7)
        }
		
		if {$trackingflag } {
		Deputs "aaaacccccccaaa:add tracking"
		ixNet setA $hTrafficItem/tracking -trackBy sourceDestPortPair0
                ixNet commit
		} else {
		
		}
		ixNet setM $hStream/framePayload \
			-customRepeat true \
			-type custom \
			-customPattern "00"
		

        if { $err } {
            return $IxiaCapi::errorcode(4)                        
        }
        return $IxiaCapi::errorcode(0)                        
    }
    
    
    body Stream::constructor_old { port portname  args } {
        global errorInfo IxiaCapi::true IxiaCapi::false
        set tag "body Stream::Ctor [info script]"
        set hPort   $port
        set hStream ""
        set srcMac ""
        set dstMac ""
		set srcIpv4 ""
        set dstIpv4 ""
		set srcIpv6 ""
        set dstIpv6 ""
        set stackLevel 1
        set flagCommit 1
		set enable_sig		0   
		set trackingflag 1
        set profileName "null"
		set PortObj $portname
		set frameLen $IxiaCapi::DefaultFrameLen
Deputs "----- TAG: $tag -----"
        Deputs "Args:$args "
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -profile -
                -profilename {
                    set profileName $value
                }
                -dstpoolname {
                    set dst $value
                }
                -srcpoolname {
                    set src $value
                }  
                -streamtype {
                    set trafficType $value
                } 
                -insertsignature {
				    if { $value == "false" } {					   
                        set trackingflag 0
					}
                }                
            }
        }
        if { ( $profileName == "vpn" ) || ( $profileName == "device" ) } {
#AgtDebugOn
Deputs "vpn or device invoking..."
#AgtDebugOff
            return
        }
        set vport $port
Deputs "vport:$vport"
        if { [ catch {
# Create stream at an undefined profile    
            if { $profileName == "null" } {
			Deputs "profileName is null"
                set profileName [TrafficManager GetProfileByIndex 0]
				Deputs "profileName :trafficmanager get $profileName"
            }
			if { $profileName != "" } {
				set ProfileName $profileName
				Deputs "profileName : $profileName"
				set proObj [ IxiaCapi::Regexer::GetObject $ProfileName ]
				Deputs "proObj:$proObj"
				$proObj AddStreamGroup $this   
            }			
            
            set root [ixNet getRoot]
            set handle [ixNet add $root/traffic trafficItem]
            ixNet setM $handle \
            -name $this
            ixNet commit
            
            ixNet setA $root/traffic/statistics/l1Rates -enabled True
            ixNet setA $root/traffic \
                    -enableDataIntegrityCheck False \
                    -enableMinFrameSize True
            ixNet commit
            if { [ info exists src ] && [ info exists dst ] } {
                                       
                set bidirection 0
                set fullMesh 0
                set selfdst 0
                set tos_tracking 0
                set no_src_dst_mesh 0
                set no_mesh 0
                set to_raw 0
                set pdu_index 1
				set enable_sig 1
                
                set srcHandle [ list ]
        Deputs "src list:$src"		
                foreach srcEndpoint $src {
        # Deputs "src:$srcEndpoint"
                    set srcObj [ GetObject $srcEndpoint ]
        # Deputs "srcObj:$srcObj"			
                    if { $srcObj == "" } {
                    Deputs "illegal object...$srcObj"
                        set srcObj $portObj
                    # error "$errNumber(1) key:src value:$src (Not an object)"                
                    }
                    
                   if { [ $srcObj isa RouteBlock ] } {
        Deputs "route block:$srcObj"
                        if { [ $srcObj cget -protocol ] == "bgp" } {
                            set routeBlockHandle [ $srcObj cget -handle ]
                            set hBgp [ ixNet getP $routeBlockHandle ]
        Deputs "bgp route block:$hBgp"
                            if { [ catch {
                                set rangeCnt [ llength [ ixNet getL $hBgp routeRange ] ]
                            } ] } {
                                set rangeCnt [ llength [ ixNet getL $hBgp vpnRouteRange ] ]
                            }
                            if { $rangeCnt > 1 } {
                                set p [ ixNet getP $routeBlockHandle ]
                                set startIndex [ string first $p $routeBlockHandle ]
                                set endIndex [ expr $startIndex + [ string length $p ] - 1 ]
                                set routeBlockHandle \
                                [ string replace $routeBlockHandle \
                                $startIndex $endIndex $p.0 ]
            Deputs "route block handle:$routeBlockHandle"		
                            } else {
                                set routeBlockHandle [ $srcObj cget -hPort ]/protocols/bgp
                            }
                            set srcHandle [ concat $srcHandle $routeBlockHandle ]
                        } else {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                        }
                        #set trafficType [ $srcObj cget -type ]
                    } elseif { [ $srcObj isa IxiaCapi::PoolNameObject ] } {
					    set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
					} elseif { [ $srcObj isa IxiaCapi::Host ] } {
					    set topstack [$srcObj cget -topStack ]
						puts "topstack: $topstack"
					    if { $topstack == "802DOT1X"} {
						     set trafficType "ethernetVlan"
						}
                        
                        #set trafficType [ $srcObj cget -UpperLayer ]
                        if {$trafficType == "ipv4"} {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topv4Handle ] ]
                        } elseif { $trafficType == "ipv6" } {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topv6Handle ] ]
                        } else {
                            set srcHandle [ concat $srcHandle [ $srcObj cget -topHandle ] ]
                        }
                    } elseif { [ $srcObj isa MulticastGroup ] } {
                        if { [ $srcObj cget -protocol ] == "mld" } {
                            set trafficType "ipv6"
                        } 
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    } elseif { [ $srcObj isa VcLsp ]   } {
                        set trafficType "ethernetVlan"
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    } else {
                    Deputs Step120
                        set srcHandle [ concat $srcHandle [ $srcObj cget -handle ] ]
                    }
                }
        Deputs "src handle:$srcHandle"

                set dstHandle [ list ]
        Deputs "dst list:$dst"		
                foreach dstEndpoint $dst {
        # Deputs "dst:$dstEndpoint"
                    set dstObj [ GetObject $dstEndpoint ]
        # Deputs "dstObj:$dstObj"			
                    if { $dstObj == "" } {
                    Deputs "illegal object...$dstEndpoint"
                     error " key:dst value:$dst"                
                    }
                   
                 
                    if { [ $dstObj isa RouteBlock ] } {
                        if { [ $dstObj cget -protocol ] == "bgp" } {
                            set routeBlockHandle [ $dstObj cget -handle ]
                            set hBgp [ ixNet getP $routeBlockHandle ]
        Deputs "bgp route block:$hBgp"
                            if { [ catch {
                                set rangeCnt [ llength [ ixNet getL $hBgp routeRange ] ]
                            } ] } {
                                set rangeCnt [ llength [ ixNet getL $hBgp vpnRouteRange ] ]
                            }
                            if { $rangeCnt > 1 } {
                                set p [ ixNet getP $routeBlockHandle ]
                                set startIndex [ string first $p $routeBlockHandle ]
                                set endIndex [ expr $startIndex + [ string length $p ] - 1 ]
                                set routeBlockHandle \
                                [ string replace $routeBlockHandle \
                                $startIndex $endIndex $p.0 ]
            Deputs "route block handle:$routeBlockHandle"		
                            } else {
                                set routeBlockHandle [ $dstObj cget -hPort ]/protocols/bgp
                            }
                            set dstHandle [ concat $dstHandle $routeBlockHandle ]
                        } else {
        Deputs "dst obj:$dstObj"				
        Deputs "route block handle:[$dstObj cget -handle]"				
                            set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                        }
                    } elseif { [ $dstObj isa IxiaCapi::PoolNameObject ] } {
					    set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
					} elseif { [ $dstObj isa IxiaCapi::Host ] } {
                       Deputs " $dstObj isa Host"
                        if {$trafficType == "ipv4"} {
                            #set dstHandle [ concat $srcHandle [ $dstObj cget -topv4Handle ] ]
                            set dstHandle [ $dstObj cget -topv4Handle ] 
                        } elseif { $trafficType == "ipv6" } {
                           # set dstHandle [ concat $srcHandle [ $dstObj cget -topv6Handle ] ]
                            set dstHandle [ $dstObj cget -topv6Handle ] 
							Deputs "dstHandle : $dstHandle"
                        } else {
                            #set dstHandle [ concat $srcHandle [ $dstObj cget -topHandle ] ]
                             set dstHandle [ $dstObj cget -topHandle ] 
                        }
                    } elseif { [ $dstObj isa MulticastGroup ] } {
                        set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                    } else {
                        set dstHandle [ concat $dstHandle [ $dstObj cget -handle ] ]
                    }
                }
        #-- advanced stream Ports/Emulations
        Deputs "Traffic type: advanced stream:$trafficType"
                  #-- Create advanced stream
                  #-- create trafficItem      
                if { $bidirection } {
                    set bi True
                } else {
                    set bi False
                }
                if { $selfdst } {
                    set sd True
                } else {
                    set sd False
                }
                if { $fullMesh } {
                    Deputs "traffic src/dst type: full mesh"		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -routeMesh oneToOne \
                         -srcDestMesh fullMesh \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan

                } else {
                    if { $no_mesh } {
        Deputs "traffic src/dst type: none"		  		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -biDirectional $bi \
                         -routeMesh oneToOne \
                         -srcDestMesh none \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan
                    } else {
        Deputs "traffic src/dst type: one 2 one"		  		  
                      ixNet setMultiA $handle \
                         -trafficItemType l2L3 \
                         -biDirectional $bi \
                         -routeMesh oneToOne \
                         -srcDestMesh oneToOne \
                         -allowSelfDestined $sd \
                         -trafficType $trafficType ;#can be ipv4 or ipv6 or ethernetVlan
                    }
                }
                if { $enable_sig } {
				Deputs "aaaaaaaaaaaaa:add tracking"
                    ixNet setA $handle/tracking -trackBy sourceDestPortPair0
                    #ixNet setA $handle/tracking -trackBy trackingenabled0
                    ixNet commit
                }
        Deputs "add endpointSet..."
                  ixNet commit
                  #-- add endpointSet
                  set endpointSet [ixNet add $handle endpointSet]
				  if { $srcHandle == "" || $dstHandle == "" } {
				       IxiaCapi::Logger::LogIn -type err -message \
                       "endpointSet element is empty, please check protocol is up " -tag $tag
                      return $IxiaCapi::errorcode(1)
				  }
        Deputs "src:$srcHandle"
                  ixNet setA $endpointSet -sources $srcHandle
        Deputs "dst:$dstHandle"
                  ixNet setA $endpointSet -destinations $dstHandle
                  
                  ixNet commit
                  set handle      [ ixNet remapIds $handle ]
        Deputs "handle:$handle"
       
                  ixNet commit
               } else {                             
                set endPoint [ixNet add $handle endpointSet]
            Deputs "port:$hPort"
                set dests [list]
                set root [ixNet getRoot]
                foreach port [ ixNet getList $root vport ] {
				#add self port to default receive list
            # Deputs "dest port:$port"
                    # if { $port == $hPort } {
                        # continue
                    # }
            # Deputs "lappend dests..."
                   lappend dests "$port/protocols"
                }
            Deputs "dests: $dests"
            # IxDebugOff
                if { [ llength $dests ] == 0 } {
                
                    ixNet setMultiA $endPoint -sources "$hPort/protocols" -destinations "$hPort/protocols"
                } else {
                
                    ixNet setMultiA $endPoint -sources "$hPort/protocols" -destinations $dests
                }
           
                ixNet commit
          
                set handle      [ ixNet remapIds $handle ]
          
                set endPoint [ ixNet remapIds $endPoint ]
                         
                if { $enable_sig } {   
Deputs "aaaaabbbbbaaa:add tracking"				
					ixNet setA $handle/tracking -trackBy sourceDestPortPair0
                    #ixNet setA $handle/tracking -trackBy trackingenabled0
					ixNet commit
				}
            }
			
        } result ] } {
            IxiaCapi::Logger::LogIn -type exception -message "$errorInfo" -tag $tag
        } else {
            set hFlow [ lindex [ ixNet getList $handle highLevelStream ] end ]
			
			set hStream [ ixNet getList $handle configElement ]
			puts "hStream: $hStream"
			ixNet setA $hStream/frameSize -fixedSize $frameLen
			ixNet commit
			ixNet setA $hFlow/frameSize -fixedSize $frameLen
			ixNet commit
			if { $profileName != "" } {
				$proObj RefreshStreamLoad
				IxiaCapi::Logger::LogIn -message "$IxiaCapi::s_StreamCtor2 \n\t\
				Profile name: $ProfileName"
			}
        }
		set hTrafficItem $handle
		Traffic ${this}_item $PortObj $hTrafficItem  
		return $this
    }
    
    
	
	body Stream::AddPdu { args } {
        global IxiaCapi::fail IxiaCapi::success IxiaCapi::true IxiaCapi::false
        global errorInfo
        
        set tag "body Stream::AddPdu [info script]"
Deputs "----- TAG: $tag -----"
Deputs "args: $args"
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -name -
                -names -
                -pduname {
                    set nameList $value
					#set nameList [::IxiaCapi::NamespaceDefine $value]
                }
            }
        }
        
        if { [ info exists nameList ] == 0 } {
            IxiaCapi::Logger::LogIn -type err -message "$IxiaCapi::s_common1 \
            $IxiaCapi::s_StreamAddPdu2" -tag $tag
                        return $IxiaCapi::errorcode(3)                        
        } else {
Deputs "name list: $nameList"
        }

        set err 0
        set index 0
		set fgindex 0
#add for modify multi vlan and mpls header
		set vlannum 0
		set mplsnum 0
#split custom header flag
		set splitcustomflag 0
        set cutcrcflag 0
		#set trackingflag 1
        foreach name $nameList {
# Read type protocol message

            if { [ catch {

                set protocol [ uplevel 1 " $name cget -protocol " ]
Deputs "Pro: $protocol "

                set type [ string toupper [ uplevel 1 " $name cget -type " ] ]
				
				if { [regexp .*(igmp).+  $protocol] } {
				Deputs "Header is igmp type, no flow tracking"
				    set trackingflag 0
				}
                set stackList [ ixNet getList $hStream stack ]
                if { ( $protocol == "custom" ) && ( $fgindex == 0 )&&([llength $stackList]== 2) } {
                    set splitcustomflag 1
                    if {[llength $nameList] == 1} {
                       set cutcrcflag 1
                       set trackingflag 0
					   
                    }
					
                }
                
Deputs "Type $type "
            } ] } {
#Deputs "Objects:[find obj]"
                IxiaCapi::Logger::LogIn -type err -message "$IxiaCapi::s_common1 \
                $IxiaCapi::s_StreamAddPdu1 $name" -tag $tag
                set err 1
                continue
            } else {
                set proStack [ GetProtocolTemp $protocol ]
Deputs "protocol stack: $proStack"
            }
# Set or Append pdu protocols
            if { [ catch {

                set stack  [ lindex [ ixNet getList $hStream stack ] 0 ]
#Deputs "type:$type"
                set needMod 1
                switch -exact -- $type {
                    SET {
#Deputs "stream:$hStream"
                        set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list:$stackList"
                        while { 1 } {
                            set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list after removal:$stackList"
                            if { [ llength $stackList ] == 2 } {
                                break
                            }
                            ixNet exec remove [ lindex $stackList [ expr [ llength $stackList ] - 2  ] ]
                        }
#Deputs "Stack ready to add:$stackList"
                        ixNet exec append [ lindex $stackList 0 ] $proStack
                        ixNet exec remove [ lindex $stackList 0 ]
                        set stack  [ lindex [ ixNet getList $hStream stack ] 0 ]
                        set stackLevel 1
                    }
                    APP {
#Deputs "stream:$hStream"
                        set stackList [ ixNet getList $hStream stack ]
#Deputs "Stack list:$stackList"
                        set appendHeader [ lindex $stackList [expr $stackLevel - 1] ]
#Deputs "appendHeader:$appendHeader"
#Deputs "stack to be added: $proStack"
                        ixNet exec append $appendHeader $proStack
                        set stack [lindex [ ixNet getList $hStream stack ] $stackLevel]
#Deputs "stack:$stack"
                        incr stackLevel
#Deputs "stackLevel:$stackLevel"
                        #set stack ${hStream}/stack:\"[ string tolower $protocol ]-${stackLevel}\"
                    }
                    MOD {
                        set index 0
                        set findflag 0
						if { $protocol == "Vlan" } {
						    set findflag [expr 0 - $vlannum]
						    incr vlannum 1
							
							
						}
						if { $protocol == "MPLS" } {
						    set findflag [expr 0 - $mplsnum]
						    incr mplsnum 1
						  
						}
#Deputs "protocol:$protocol"
                        foreach pro [ ixNet getList $hStream stack ] {
#Deputs "pro:$pro"
                            if { [ regexp -nocase $protocol $pro ] } {
                                if { [ regexp -nocase "${pro}\[a-z\]+" $stack ] == 0 } {
                                   incr findflag 1
									if { $findflag == 1 } {
									    break
									}
                                }
                            }
                            incr index
                        }
                        Deputs "findflag: $findflag"
						if { $findflag != 1 } {
						    set stackList [ ixNet getList $hStream stack ]
							Deputs "stackList: $stackList"
							
						    switch -exact -- $name {
							    ::::IxiaCapi::pdul2_1 -
								:::IxiaCapi::pdul2_1 -
								::IxiaCapi::pdul2_1 {
									set MstackLevel 1									
								}
                                ::::IxiaCapi::pdul4 -
                                :::IxiaCapi::pdul4 -								
								::IxiaCapi::pdul4 {
								Deputs "add L4 header"
									set MstackLevel [expr [llength $stackList] - 1]
								Deputs "MstackLevel:$MstackLevel"
									
								}	
							}
							
#Deputs "Stack list:$stackList"
                            set appendHeader [ lindex $stackList [expr $MstackLevel - 1] ]
#Deputs "appendHeader:$appendHeader"
#Deputs "stack to be added: $proStack"
                            ixNet exec append $appendHeader $proStack
                            set stack [lindex [ ixNet getList $hStream stack ] $MstackLevel]
							incr MstackLevel
#Deputs "stack:$stack"
                            
						} else {
						    set stack $pro
						}
                    }
                    default { }
                }
                ixNet commit
                catch {
                    set stack [ ixNet remapIds $stack ]
                }
#Deputs "Stack:$stack"
                set appendHeader $stack
#Deputs "Stack list:[ ixNet getList $hStream stack ]"
            } ] } {

                IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
#Deputs "error occured..."
                set err 1
                continue
            }
            if { $needMod == 0 } {

                incr index
                continue
            }
# Modify fields
            if { [ catch {
			    if {$protocol == "custom"} {
				    if { $splitcustomflag } {
					    set raw [ uplevel 1 " $name cget -raw " ]
						set raw [ List2Str $raw ]
						if { [ regexp -nocase {^0x} $raw ] } {
                            set raw [string range $raw 2 end]                        
						} 
				Deputs "qqqqqqqqqqqqqqq [string length $raw] ,[ixNet setA $hStream/frameSize -fixedSize] "
						if {[string length $raw] < [ixNet setA $hStream/frameSize -fixedSize]} {
						    set cutcrcflag 0
					    }
						set ethstack  [ lindex [ ixNet getList $hStream stack ] 0 ]
						set ethfieldList [ ixNet getList $ethstack field ]
						set dstethvalue [string range $raw 0 11]
                        set dstethvalue [MacTrans $dstethvalue]
                        Deputs $dstethvalue
						set srcethvalue [string range $raw 12 23]
                        set srcethvalue [MacTrans $srcethvalue]
                        Deputs $srcethvalue
						set ethtypevalue [string range $raw 24 27]
                        Deputs $ethtypevalue
                     
						ixNet setA [ lindex $ethfieldList 0 ] \
                        -auto false \
                        -valueType singleValue \
                        -singleValue $dstethvalue
                        ixNet commit
                        
						ixNet setA [ lindex $ethfieldList 1 ] \
                        -auto false \
                        -valueType singleValue \
                        -singleValue $srcethvalue
                        ixNet commit
						set ethtypefield [ lindex $ethfieldList 2 ]
					
						ixNet setA $ethtypefield -auto False
					                              
						ixNet setMultiAttrs $ethtypefield \
                                -valueType singleValue \
                                -singleValue $ethtypevalue
						ixNet commit
						
						set customStack $stack
		#Deputs "customStack:$customStack"
						set fieldList [ ixNet getList $customStack field ]
		#Deputs "fieldList: $fieldList"
                        if {$cutcrcflag} {
                            set rawlen [string length $raw]
                            set rawindex [expr $rawlen - 9]
                            set raw [string range $raw 28 $rawindex]
                        } else {
                            set raw [string range $raw 28 end]
                        }
	                  
						set rawLen [expr [string length $raw] * 4]
		#Deputs "rawLen:$rawLen"
						ixNet setA [ lindex $fieldList 0 ] -singleValue $rawLen
						
						ixNet commit
						ixNet setA [ lindex $fieldList 1 ] -singleValue 0x$raw
						
						ixNet commit
					} else {
					    set raw [ uplevel 1 " $name cget -raw " ]
		#Deputs "raw: $raw"
						set raw [ List2Str $raw ]
		#Deputs "raw: $raw"
						#set customStack [ lindex [ ixNet getList $hStream stack ] 0 ]
						set customStack $stack
		#Deputs "customStack:$customStack"
						set fieldList [ ixNet getList $customStack field ]
		#Deputs "fieldList: $fieldList"
						set rawLen [expr [string length $raw] * 4]
		#Deputs "rawLen:$rawLen"
						ixNet setA [ lindex $fieldList 0 ] -singleValue $rawLen
						
						ixNet commit
						if { [ regexp -nocase {^0x} $raw ] } {
		
							ixNet setA [ lindex $fieldList 1 ] -singleValue $raw
						} else {
		
							ixNet setA [ lindex $fieldList 1 ] -singleValue 0x$raw
						}
						ixNet commit
					}
				   					
					
				} else {
                    if {$protocol == "igmpv2" ||$protocol == "igmpv1"} {
                        set index 0
                        foreach pro [ ixNet getList $hStream stack ] {
    Deputs "pro:$pro"
                            if { [ regexp -nocase ipv4 $pro ] } {
                                if { [ regexp -nocase "ipv4\[a-z\]+" $pro ] == 0 } {
                                    set ipv4stack $pro
                                    incr index
                                    break
                                }
                            incr index    
                            }
                           
                        }
                        #set ipv4stack [ lindex [ ixNet getList $hStream stack ] $index ]
    Deputs "ipv4stack:$ipv4stack" 
                        
                        set totalheader [lindex [ixNet getL $ipv4stack field ] 17]
    Deputs "totalheader:$totalheader" 
                        ixNet setA $totalheader \
                        -auto false \
                        -valueType singleValue \
                        -singleValue 28
                        ixNet commit
                    }

                    set fieldModes [ uplevel 1 " $name cget -fieldModes " ]
                    set fields [ uplevel 1 " $name cget -fields " ]
                    set fieldConfigs [ uplevel 1 " $name cget -fieldConfigs " ]
                    set optional [ uplevel 1 " $name cget -optionals " ]
                    set autos [ uplevel 1 " $name cget -autos " ]
#Deputs "name list len: [llength $nameList]"
                    if { [ lsearch -exact $fields "etherType" ] < 0 } {
                        if { [ llength $nameList ] == 1 } {

#Deputs "protocol:$protocol"
                            if { [ string tolower $protocol ] == "ethernet" } {

                                lappend fieldModes Fixed
                                lappend fields     etherType
                                lappend fieldConfigs 0x88b5
                                lappend autos       0
                                lappend optional    0
                            }
                        } else {
                            if { [ string tolower $protocol ] == "ethernet" } {

                                lappend fieldModes Reservedf
                                lappend fields     etherType
                                lappend fieldConfigs 0
                                lappend autos       1
                                lappend optional    0
                            }
                        }
                    }
Deputs "PDU:\n\tModes:$fieldModes\n\tFields:$fields\n\tConfigs:$fieldConfigs\n\tOptional:$optional\n\tAutos:$autos"
                    foreach mode $fieldModes field $fields conf $fieldConfigs\
                        opt $optional auto $autos {
#Deputs "stack:$stack"
#Deputs "field:$field"
                        set obj [ GetField $stack $field ]
#Deputs "Field object: $obj"

                        if { [ info exists opt ] } {
                            if { $opt == "" } { continue }
                            if { $opt } {
							    ixNet setA $obj -activeFieldChoice True
								 
                                ixNet setA $obj -optionalEnabled True
                                continue
                            }
                        } else {
                            continue
                        }
                        if { [ info exists auto ] } {

                            if { $auto == "" } { continue }

                            if { $auto } {

                                ixNet setA $obj -auto True
                                continue
                            } else {
                            
                                ixNet setA $obj -auto False
                            }
                        } else {
                            continue
                        }
                        if { [ info exists mode ] == 0 || [ info exists field ] == 0 ||\
                            [ info exists conf ] == 0 } {
#Deputs "continue"
                            continue
                        }
Deputs "Mode:$mode"
                        switch -exact $mode {
                            Fixed {
#Deputs "Fixed:$protocol\t$field\t$conf"
                                ixNet setMultiAttrs $obj \
                                -valueType singleValue \
                                -singleValue $conf
                            }
                            List {
#Deputs "List:$protocol\t$field\t$conf"
                                ixNet setMultiAttrs $obj \
                                -valueType valueList
                                -valueList $conf
                            }
                            Segment {
#                            set offset [ AgtInvoke AgtPduHeader GetFieldBitOffset \
#                                $hPdu $protocol 1 $field ]
#Deputs "Offset: $offset"
#                            AgtInvoke AgtRawPdu SetPduBytes $hPdu \
#                                [ expr $offset / 8 ] [ string length $conf ] $conf
                            }
                            Reserved {
#Deputs "Reserved...continue"
                                continue
                            }
                            Incrementing -
                            Decrementing {
                                set mode [string range $mode 0 8]
                                set mode [string tolower $mode]
Deputs "Mode:$mode\tProtocol:$protocol\tConfig:$conf"
                                set start [lindex $conf 1]
                                set count [lindex $conf 2]
                                set step  [lindex $conf 3]
#Deputs "obj:$obj mode: $mode start:$start count:$count step:$step"
                                ixNet setMultiAttrs $obj \
                                -valueType $mode \
                                -countValue $count \
                                -stepValue $step \
                                -startValue $start
                            }
                            Commit {
                                ixNet setMultiAttrs $obj \
                                -valueType singleValue \
                                -singleValue $conf
                                ixNet commit
                            }
                            MultiField {
                                ixNet setMultiAttrs $obj \
                                -valueType singleValue \
                                -singleValue [lindex $conf 0]
                                ixNet commit
                                set index 1
                                regexp  {(.+)-([0-9]+)} $obj total world num                                 
                                while {$index < [llength $conf] } {
                                    set newindex [expr $num + $index]
                                    regsub {multicastSource-([0-9]+)} $obj multicastSource-${newindex} newobj
                                Deputs $newobj
                                    ixNet setMultiAttrs $newobj \
                                        -activeFieldChoice true  \
                                        -valueType singleValue \
                                        -singleValue [lindex $conf $index]
                                    ixNet commit
                                    incr index
                                }
                                
                            }
                        }
						ixNet commit
                    }
                }
		    }] } {

                IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
Deputs "error occured..."
                set err 1
                IxiaCapi::Logger::LogIn -type warn -message \
                "$IxiaCapi::s_StreamAddPdu3 $name" -tag $tag
                continue
            } else {
                IxiaCapi::Logger::LogIn -message "$IxiaCapi::s_StreamAddPdu4 $name"
            }
            incr index
			incr fgindex
        }

        if { [ catch {

            ixNet commit
        } ] } {
            IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
                    return $IxiaCapi::errorcode(7)
        }
		
		if {$trackingflag } {
		Deputs "aaaacccccccaaa:add tracking"
            if { $flowflag } {
                ixNet setA $hTrafficItem/tracking -trackBy [list flowGroup0 sourceDestPortPair0]
            } else {
                ixNet setA $hTrafficItem/tracking -trackBy sourceDestPortPair0
            }
		
            ixNet commit
		}
		ixNet setM $hStream/framePayload \
			-customRepeat true \
			-type custom \
			-customPattern "00"
		

        if { $err } {
            return $IxiaCapi::errorcode(4)                        
        }
        return $IxiaCapi::errorcode(0)                        
    }
    
    
    body Stream::ClearPdu {} {
        global IxiaCapi::fail IxiaCapi::success
        if { [ catch {
            AgtInvoke AgtStreamGroup SetPduHeaders $hStream \
            [ AgtInvoke AgtStreamGroup GetDefaultL2Protocol $portObj ]
            } result ] } {
            IxiaCapi::Logger::LogIn -type err -message "$errorInfo" -tag $tag
                        return $IxiaCapi::errorcode(7)                        
        } else {
                        return $IxiaCapi::errorcode(0)                        
        }
    }
    body Stream::destructor {} {
        global errorInfo
        if { [
        catch {
            #ixNet setA $hStream -suspend True
			
			if { $flowflag == 1 } {
			     delete object ${this}_flow
			} else {
			    ixNet remove $hTrafficItem
            ixNet commit
			    delete object ${this}_item
			}
        }
        ] } {
Deputs $errorInfo
        }
    }
    body Stream::DestroyPdu { args } {
        global IxiaCapi::fail IxiaCapi::success IxiaCapi::true IxiaCapi::false
        global errorInfo
        
        set tag "body Stream::DestroyPdu [info script]"
Deputs "----- TAG: $tag -----"
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -name -
                -names -
                -pduname {
                    set nameList $value
					#set nameList [ IxiaCapi::NamespaceConvert $value $PduList ]
                }
            }
        }
        
        if { [ info exists nameList ] == 0 } {
            #IxiaCapi::Logger::LogIn -type err -message "$IxiaCapi::s_common1 \
            #$IxiaCapi::s_StreamAddPdu2" -tag $tag
            #            return $IxiaCapi::errorcode(3)
            IxiaCapi::TrafficManager DeleteAllPdu
                        return $IxiaCapi::errorcode(0)                        
            
        }
        
        foreach pdu $nameList {
            if { [ catch {
                set obj [ IxiaCapi::Regexer::GetObject $pdu ]
                delete object $obj
                #uplevel 1 "delete object $pdu"
            } ] } {
Deputs "$errorInfo"
            }
        }
                        return $IxiaCapi::errorcode(0)                        
    }
    body Stream::GetProtocolTemp { pro } {
Deputs "Get protocol..."
Deputs "protocol to match:$pro"
        set root [ixNet getRoot]
        set protocolTemplateList [ ixNet getList $root/traffic protocolTemplate ]
        set index 0
        foreach protocol $protocolTemplateList {
            if { [ regexp -nocase $pro $protocol ] } {
                if { [ regexp -nocase "${pro}\[a-z\]+" $protocol ] == 0 } {
                    break
                }
            }
            incr index
        }
        if { $index < [llength $protocolTemplateList] } {
            return [ lindex $protocolTemplateList $index ]
        } else {
            return ""
        }
    }
    
    body Stream::GetField { stack value } {
Deputs "value:$value"
Deputs "stack: $stack"
        set stack [lindex $stack 0]
        set fieldList [ ixNet getL $stack field ] 
		
#Deputs "fieldList:$fieldList"
        set index 0
        foreach field $fieldList {
#Deputs "field:$field"
            if { [ regexp $value $field ] } {
                if { [ regexp "${value}\[a-z\]+" $field ] == 0 } {
                    break
                }
            }
            incr index
        }
        if { $index < [llength $fieldList] } {
            return [ lindex $fieldList $index ]
        } else {
            return ""
        }
    }
    
    body Stream::SetProfileParam {} {
        set tag "body Stream::SetProfileParam [info script]"
Deputs "----- TAG: $tag -----"
        set rateUnit    1

        set proObj [ IxiaCapi::Regexer::GetObject $ProfileName ]
        set type [ uplevel "$proObj cget -Type" ]
        set port [ uplevel "$proObj cget -hPort" ]
        set mode [ uplevel "$proObj cget -Mode" ]
        set load [ uplevel "$proObj cget -TrafficLoad" ]
        set streamCnt [ uplevel "$proObj GetStreamCount" ]
        set load [ expr $load / ${streamCnt}.0 ]
        set unit [ uplevel "$proObj cget -TrafficLoadUnit" ]
        set bSize [ uplevel "$proObj cget -BurstSize" ]
        if {$bSize != ""} {
		    set bSize [ expr $bSize / ${streamCnt} ]
		}
        set frameLen [ uplevel "$proObj cget -FrameLen" ]
Deputs "proObj:$proObj type:$type port:$port mode:$mode load:$load unit:$unit bSize:$bSize frameLen:$frameLen"
Deputs "hStream: $hStream"
        set portspeed [ixNet getA $hPort -actualSpeed]

        switch $unit {
            PPS -
            FPS -
            L3MBPS {
                ixNet setA $hStream/frameRate -type framesPerSecond
            }
            PERCENT {
                ixNet setA $hStream/frameRate -type percentLineRate
            }
            MBPS -
            BPS -
            KBPS {
                #ixNet setA $hStream/frameRate -type bitsPerSecond
				ixNet setA $hStream/frameRate -type percentLineRate
            }
        }

        switch $unit {
            MBPS {
			    set load [expr $load * 100.0 / $portspeed]
                #ixNet setA $hStream/frameRate -bitRateUnitsType mbitsPerSec
            }
            L3MBPS {
                set rateUnit    1000000
            }
            BPS {
			    set load [expr $load * 10000.0 / $portspeed]
                #ixNet setA $hStream/frameRate -bitRateUnitsType bitsPerSec
            }
            KBPS {
			     set load [expr $load * 10.0 / $portspeed]
                #ixNet setA $hStream/frameRate -bitRateUnitsType kbitsPerSec
            }
        }
        set load [expr $load * $rateUnit]
        ixNet setA $hStream/frameRate -rate $load
        
        if { $type == "CONSTANT" || $type == "BURST"} {
            if { $type == "BURST"|| $bSize != "" } {
                ixNet setA $hStream/transmissionControl -type fixedFrameCount
                ixNet setA $hStream/transmissionControl -frameCount $bSize
				ixNet setA $hStream/transmissionControl -burstPacketCount $bSize
            } else {
                ixNet setA $hStream/transmissionControl -type continuous
            }
        } else {
            ixNet setA $hStream/transmissionControl -type custom
			ixNet setA $hStream/transmissionControl -burstPacketCount $bSize
        }

       
        
        ixNet commit
    }
}
