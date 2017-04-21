--
-- Version 01 JUNI 2016 
-- Frank Thingholm
--

-- FOR MYSQL
create database NetFlow
	character set 'utf8'
	collate utf8_general_ci;
-- FOR POSTGRESQL
-- create database NetFlow;
-- END
   
use NetFlow;


-- ------------------------------------------------
-- GLOBAL OBJECTS - these are NOT customer editable
-- ------------------------------------------------


create table GlobalServiceObjects (
	GlobalServiceObjectID int PRIMARY KEY,
		
	IPProtocolName		varchar(16)  NOT NULL,			-- short name e.g. TCP, GRE
	IPProtocolNumber	int NOT NULL,					-- tcp/udp/icmp/gre/... 
	ServiceName			varchar(16)  NOT NULL,			-- short name e.g. smtp/ssh/ ...
	PortNumber			int,		
	    check (Portnumber between 0 and 65535),
	Description			varchar(256) NOT NULL   
);


create table GlobalNetworkObjects (
	GlobalNetworkObjectID int PRIMARY KEY,
   
    Name                varchar(32) NOT NULL,
	Image				blob   							-- A (national-) flag
);

create table GlobalNetworkObjectCIDRs (
	GlobalNetworkObjectCIDRID int PRIMARY KEY,

	GlobalNetworkObjectID int,
   
    Name                varchar(32) NOT NULL,
-- FOR MYSQL   
	net					varchar(39) NOT NULL,			-- In CIDR format
-- FOR POSTGRESQL
--	net					cidr NOT NULL,
-- END				
	Kind				char(4) NOT NULL,	 			-- 'IPv4' or 'IPv6'
	    check (Kind IN ('IPv4', 'IPv6')),
    
    foreign key (GlobalNetworkObjectID) references GlobalNetworkObjects(GlobalNetworkObjectID) on delete RESTRICT on update RESTRICT
);


-- -------------------------------------------------------------------------------------
-- CUSTOMERS, THEIR NETWORKS AND ADMINISTRATORS - these are mostly NOT customer editable
-- -------------------------------------------------------------------------------------

   
create table Customers (
	CustomerID			int PRIMARY KEY,

	CompanyName			varchar(80) NOT NULL,			-- customer editable
	
	CompanyAdr1			varchar(80) NOT NULL,			-- customer editable
	CompanyAdr2			varchar(80) NOT NULL,			-- customer editable
	CompanyAdr3			varchar(80) NOT NULL,			-- customer editable
	CompanyAdr4			varchar(80) NOT NULL,			-- customer editable
		
	AccountantName		varchar(80) NOT NULL,			-- customer editable
	AccountantEmail		varchar(80) NOT NULL,			-- customer editable
	AccountantPhone		varchar(80) NOT NULL,			-- customer editable
		
	HourlyRate			NUMERIC(10,2) NOT NULL,			-- not customer editable
	SubscriptionFee		NUMERIC(10,2) NOT NULL,			-- not customer editable
	DeductionPct		NUMERIC(10,2) NOT NULL,			-- not customer editable
	
	MainMail			varchar(80),
	MainPhone			varchar(80),
	MainUrl				varchar(80),
	
	CVR					char(8) UNIQUE KEY,
	EAN					char(13) UNIQUE KEY,
    	
   	Valid				boolean NOT NULL
);
 
create table CustomerNetworks (
	CustomerNetworkID	int PRIMARY KEY,
   
	CustomerID			int NOT NULL,

    Name                varchar(32) NOT NULL,   
	Kind				char(4) NOT NULL,	    		-- 'IPv4' or 'IPv6'
		check (Kind in ('IPv4', 'IPv6')),		
-- FOR MYSQL   
	net					varchar(39) NOT NULL,			-- In CIDR format
														-- Ex. '191.11.22.33/28' http://stackoverflow.com/questions/3455320/size-for-storing-ipv4-ipv6-addresses-as-a-string
-- FOR POSTGRESQL
--	net					cidr NOT NULL,
-- END				
   
	foreign key (CustomerID) references Customers(CustomerID) on delete RESTRICT on update RESTRICT
);
  
create table Administrators (
	AdministratorID		int PRIMARY KEY,
	   
	CustomerID			int NOT NULL,
		   
	Kind				varchar(8) NOT NULL, 			-- 'DBADMIN', 'NETADMIN'
	    check (Kind IN ('DBADMIN', 'NETADMIN')),
	Name				varchar(80) NOT NULL,
	Phone				varchar(80),
		   
	Username			varchar(32) NOT NULL UNIQUE KEY, -- Must be email address
	Password			varchar(32) NOT NULL,
	    check (len(Password)>=12),
		   
	Valid				boolean NOT NULL,
   
	LastLogin			datetime,
	LastPasswordChange	datetime,
   
	foreign key (CustomerID) references Customers(CustomerID) on delete RESTRICT on update RESTRICT
);
 
create table NetworkRights (
	NetworkRightID		int PRIMARY KEY,
   
	CustomerNetworkID	int NOT NULL,
	AdministratorID		int NOT NULL,
   
	MaxBlockMins		int,	 						-- NULL means no limit
	    check (MaxBlockMins>0),
   
	foreign key (CustomerNetworkID) references CustomerNetworks(CustomerNetworkID) on delete RESTRICT on update RESTRICT,
	foreign key (AdministratorID) references Administrators(AdministratorID) on delete RESTRICT on update RESTRICT
);


-- --------------------------------------------
-- Customer Networks Objects and FlowSpec Rules
-- --------------------------------------------

create table FastNetMonInstances (
	FastNetMonInstanceID int PRIMARY KEY,
	
	CustomerID			int,
	
	Mode				varchar(7),
		check (Mode in ('DETECT', 'ENFORCE')),
		
	foreign key (CustomerID) references Customers(CustomerID)
);

create table CustomerNetworkObjects (
	CustomerNetworkObjectID	int PRIMARY KEY,

	CustomerNetworkID	int,

    Name                varchar(32) NOT NULL,   
	Kind				char(4) NOT NULL,	  			-- 'IPv4' eller 'IPv6'
	    check (Kind IN ('IPv4', 'IPv6')),
-- FOR MYSQL   
	net					varchar(39) NOT NULL,			-- In CIDR format
														-- Ex. '191.11.22.33/28' http://stackoverflow.com/questions/3455320/size-for-storing-ipv4-ipv6-addresses-as-a-string
-- FOR POSTGRESQL
--	net					inet NOT NULL,
-- END				
    
	foreign key (CustomerNetworkID) references CustomerNetworks(CustomerNetworkID) on delete RESTRICT on update RESTRICT
);
 
create table FlowSpecRules (
	-- Never delete records
	-- Changes must be saved in a new record, the old must be terminated (ValidTo in old record and ValidFrom in new record must be adjusted)
   
	FlowSpecRuleID		int PRIMARY KEY,
   
	CustomerNetworkID	int NOT NULL,
   
	-- Rule metadata
   
	AdministratorID		int NOT NULL, 		 			-- Creator
   			
	Direction			varchar(3) NOT NULL, 			-- 'IN' or 'OUT'
	    check (Direction IN ('IN', 'OUT')),
	ValidFrom			datetime NOT NULL,
	ValidTo				datetime NOT NULL,
	    check (ValidTo > ValidFrom),

	FastNetMonInstanceID int,							-- If NULL then rule is manually created
   
	IsActivated			boolean NOT NULL,
	IsExpired			boolean NOT NULL,
 
	-- FlowSpec fields
   
-- FOR MYSQL   
	DestinationPrefix	varchar(39),					-- In CIDR format
														-- Ex. '191.11.22.33/28' http://stackoverflow.com/questions/3455320/size-for-storing-ipv4-ipv6-addresses-as-a-string
-- FOR POSTGRESQL
--	DestinationPrefix	inet,
-- END				
-- FOR MYSQL   
	SourcePrefix		varchar(39),					-- In CIDR format
														-- Ex. '191.11.22.33/28' http://stackoverflow.com/questions/3455320/size-for-storing-ipv4-ipv6-addresses-as-a-string
-- FOR POSTGRESQL
--	SourcePrefix		inet,
-- END				
	IPProtocol			varchar(8),						-- DATATYPE!
	SrcOrDestPort		varchar(80),					-- DATATYPE!
	DestinationPort		varchar(80),					-- DATATYPE!
	SourcePort			varchar(80),					-- DATATYPE!
	ICMPType			int,				
	ICMPCode			int,				
	TCPflags			int,				
	PacketLength		int,				
	DSCP				varchar(80),					-- DATATYPE!
	FragmentEncoding	int,
   
	foreign key (CustomerNetworkID) references CustomerNetworks(CustomerNetworkID) on delete RESTRICT on update RESTRICT,
	foreign key (AdministratorID) references Administrators(AdministratorID) on delete RESTRICT on update RESTRICT,
	foreign key (FastNetMonInstanceID) references FastNetMonInstances(FastNetMonInstanceID)
);
