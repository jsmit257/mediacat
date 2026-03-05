PRAGMA foreign_keys = ON;

create table inodes (
	inode integer not null primary key
);

create table paths (
	id       integer not null primary key, -- could use inode
	name     varchar not null,
	parentid integer     null references paths(id),
	unique(name, parentid)
);

create index fk_paths_parentid on paths(parentid);

create table files (
	id    integer not null primary key references paths(id),
	inode integer not null references inodes(inode)
);

create index fk_files_inode on files(inode);

create table tagnames (
	id      integer not null primary key,
	tagname varchar not null unique
);

create table tagvalues (
	id        integer not null primary key,
	tagvalue  varchar not null,
	inode     integer not null references inodes(inode),
	tagnameid integer not null references tagnames(id)
);

create index fk_tagvalues_inode on tagvalues(inode);
create index fk_tagvalues_tagnameid on tagvalues(tagnameid);

create table transients (
	cookie   varchar  not null primary key,
	oldpath  integer  not null references paths(id),
	filetype char(1)  not null,
	created  datetime not null default current_timestamp
);

-- transients is too small (usually empty) to need a foreign key index

create view fullpaths 
as
with recursive fp(id, fullpath, depth)
as (
	select  id
	       ,name as fullpath
				 ,0    as depth
	  from  paths 
	 where  parentid is null
	union all
	select  p.id
	       ,fp.fullpath || '/' || p.name
				 ,fp.depth + 1
	  from  paths p
	  join  fp
	    on  p.parentid = fp.id
)
select  id
       ,fullpath
			 ,depth
  from  fp
;

create view tags
as
select  inode
       ,tagname
       ,tagvalue
  from  tagvalues tv
  join  tagnames  tn
    on  tv.tagnameid = tn.id
;

create view filetags
as
select  t.inode
       ,t.tagname
       ,t.tagvalue
       ,fp.fullpath as fullname
  from  tags      t
  join  files     f
    on  t.inode   = f.inode
  join  fullpaths fp
    on  f.id      = fp.id
;

create view orphans
as
with recursive
linked(pathid) as (
	select  id
	  from  files
	union
	select  parentid
	  from  paths
), unlinked(pathid) as (
	select  p.id
	  from  paths p
	  left
	  join  linked l
	    on  p.id = l.parentid
	 where  l.parentid is null
	 union  all
	select  p.id
	  from  paths p
	  join  unlinked u
	    on  p.parentid = u.pathid
)
select  pathid
  from  unlinked
;

