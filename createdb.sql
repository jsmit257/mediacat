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

--
-- build trees using every path as a tree root
--
create view allpaths
as
with recursive
ap(start, end, path, depth) as (
	select  id   as start
	       ,id   as end
	       ,name as path
	       ,0    as depth
	  from  paths
	union all
	select  ap.start
	       ,p.id
	       ,ap.path || '/' || p.name
	       ,ap.depth + 1
	  from  paths p
	  join  ap
	    on  p.parentid = ap.end
)
select  start
       ,end
       ,path
       ,depth
  from  ap
;

--
-- just the tree with paths starting at the parent-less root
--
create view fullpaths
as
select  end as id
       ,path as fullpath
       ,depth
  from  allpaths
 where  start = 1
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
--
-- build paths from the leaves (files) down to the root
--
linked(parentid) as (
	select  id
	  from  files
	union
	select  p.parentid
	  from  linked l
	  join  paths p
	    on  l.parentid = p.id
)
--
-- then select all the nodes that don't support a leaf
--
select  p.id
  from  paths p
  left
  join  linked l
    on  p.id = l.parentid
 where  l.parentid is null
;

create view pruned
as
select  fp.fullpath as file
       ,f.inode
       ,count(links.id) as linkcount
       ,t.created
  from  transients t
  join  allpaths   ap
    on  t.oldpath  = ap.start
  join  files      f
    on  ap.end     = f.id
  join  fullpaths  fp
    on  f.id       = fp.id
  left
  join  files      links
    on  f.inode    = links.id
 group
    by  fp.fullpath
       ,f.inode
       ,t.created
;

