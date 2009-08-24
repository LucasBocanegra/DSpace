--
-- database_schema.sql (ORACLE version!)
--
-- Version: $Revision$
--
-- Date:    $Date$
--
-- Copyright (c) 2002-2009, The DSpace Foundation.  All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
-- 
-- - Redistributions of source code must retain the above copyright
-- notice, this list of conditions and the following disclaimer.
-- 
-- - Redistributions in binary form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
-- 
-- - Neither the name of the DSpace Foundation nor the names of its
-- contributors may be used to endorse or promote products derived from
-- this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-- A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
-- OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
-- TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
-- USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
-- DAMAGE.


CREATE SEQUENCE bitstreamformatregistry_seq;
CREATE SEQUENCE fileextension_seq;
CREATE SEQUENCE bitstream_seq;
CREATE SEQUENCE eperson_seq;
CREATE SEQUENCE epersongroup_seq START WITH 2;
-- we reserve 0 and 1
CREATE SEQUENCE item_seq;
CREATE SEQUENCE bundle_seq;
CREATE SEQUENCE item2bundle_seq;
CREATE SEQUENCE bundle2bitstream_seq;
CREATE SEQUENCE dctyperegistry_seq;
CREATE SEQUENCE dcvalue_seq;
CREATE SEQUENCE community_seq;
CREATE SEQUENCE collection_seq;
CREATE SEQUENCE community2community_seq;
CREATE SEQUENCE community2collection_seq;
CREATE SEQUENCE collection2item_seq;
CREATE SEQUENCE resourcepolicy_seq;
CREATE SEQUENCE epersongroup2eperson_seq;
CREATE SEQUENCE handle_seq;
CREATE SEQUENCE workspaceitem_seq;
CREATE SEQUENCE workflowitem_seq;
CREATE SEQUENCE tasklistitem_seq;
CREATE SEQUENCE registrationdata_seq;
CREATE SEQUENCE subscription_seq;
CREATE SEQUENCE history_seq;
CREATE SEQUENCE historystate_seq;
CREATE SEQUENCE communities2item_seq;
CREATE SEQUENCE epersongroup2workspaceitem_seq;
CREATE SEQUENCE metadataschemaregistry_seq;
CREATE SEQUENCE metadatafieldregistry_seq;
CREATE SEQUENCE metadatavalue_seq;
CREATE SEQUENCE group2group_seq;
CREATE SEQUENCE group2groupcache_seq;

-------------------------------------------------------
-- BitstreamFormatRegistry table
-------------------------------------------------------
CREATE TABLE BitstreamFormatRegistry
(
  bitstream_format_id INTEGER PRIMARY KEY,
  mimetype            VARCHAR2(256),
  short_description   VARCHAR2(128) UNIQUE,
  description         VARCHAR2(2000),
  support_level       INTEGER,
  -- Identifies internal types
  internal             NUMBER(1)
);

-------------------------------------------------------
-- FileExtension table
-------------------------------------------------------
CREATE TABLE FileExtension
(
  file_extension_id    INTEGER PRIMARY KEY,
  bitstream_format_id  INTEGER REFERENCES BitstreamFormatRegistry(bitstream_format_id),
  extension            VARCHAR2(16)
);

CREATE INDEX fe_bitstream_fk_idx ON FileExtension(bitstream_format_id);

-------------------------------------------------------
-- Bitstream table
-------------------------------------------------------
CREATE TABLE Bitstream
(
   bitstream_id            INTEGER PRIMARY KEY,
   bitstream_format_id     INTEGER REFERENCES BitstreamFormatRegistry(bitstream_format_id),
   name                    VARCHAR2(256),
   size_bytes              INTEGER,
   checksum                VARCHAR2(64),
   checksum_algorithm      VARCHAR2(32),
   description             VARCHAR2(2000),
   user_format_description VARCHAR2(2000),
   source                  VARCHAR2(256),
   internal_id             VARCHAR2(256),
   deleted                 NUMBER(1),
   store_number            INTEGER,
   sequence_id             INTEGER
);

CREATE INDEX bit_bitstream_fk_idx ON Bitstream(bitstream_format_id);

-------------------------------------------------------
-- EPerson table
-------------------------------------------------------
CREATE TABLE EPerson
(
  eperson_id          INTEGER PRIMARY KEY,
  email               VARCHAR2(64) UNIQUE,
  password            VARCHAR2(64),
  firstname           VARCHAR2(64),
  lastname            VARCHAR2(64),
  can_log_in          NUMBER(1),
  require_certificate NUMBER(1),
  self_registered     NUMBER(1),
  last_active         TIMESTAMP,
  sub_frequency       INTEGER,
  phone	              VARCHAR2(32),
  netid               VARCHAR2(64) UNIQUE,
  language            VARCHAR2(64)
);

-- index by email
CREATE INDEX eperson_email_idx ON EPerson(email);

-- index by netid
CREATE INDEX eperson_netid_idx ON EPerson(netid);

-------------------------------------------------------
-- EPersonGroup table
-------------------------------------------------------
CREATE TABLE EPersonGroup
(
  eperson_group_id INTEGER PRIMARY KEY,
  name             VARCHAR2(256) UNIQUE
);

------------------------------------------------------
-- Group2Group table, records group membership in other groups
------------------------------------------------------
CREATE TABLE Group2Group
(
  id        INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES EPersonGroup(eperson_group_id),
  child_id  INTEGER REFERENCES EPersonGroup(eperson_group_id)
);

CREATE INDEX g2g_parent_fk_idx ON Group2Group(parent_id);
CREATE INDEX g2g_child_fk_idx ON Group2Group(child_id);

------------------------------------------------------
-- Group2GroupCache table, is the 'unwound' hierarchy in
-- Group2Group.  It explicitly names every parent child
-- relationship, even with nested groups.  For example,
-- If Group2Group lists B is a child of A and C is a child of B,
-- this table will have entries for parent(A,B), and parent(B,C)
-- AND parent(A,C) so that all of the child groups of A can be
-- looked up in a single simple query
------------------------------------------------------
CREATE TABLE Group2GroupCache
(
  id        INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES EPersonGroup(eperson_group_id),
  child_id  INTEGER REFERENCES EPersonGroup(eperson_group_id)
);

CREATE INDEX g2gc_parent_fk_idx ON Group2GroupCache(parent_id);
CREATE INDEX g2gc_child_fk_idx ON Group2GroupCache(child_id);

-------------------------------------------------------
-- Item table
-------------------------------------------------------
CREATE TABLE Item
(
  item_id         INTEGER PRIMARY KEY,
  submitter_id    INTEGER REFERENCES EPerson(eperson_id),
  in_archive      NUMBER(1),
  withdrawn       NUMBER(1),
  last_modified   TIMESTAMP,
  owning_collection INTEGER
);

CREATE INDEX item_submitter_fk_idx ON Item(submitter_id);

-------------------------------------------------------
-- Bundle table
-------------------------------------------------------
CREATE TABLE Bundle
(
  bundle_id          INTEGER PRIMARY KEY,
  mets_bitstream_id  INTEGER REFERENCES Bitstream(bitstream_id),
  name               VARCHAR2(16),  -- ORIGINAL | THUMBNAIL | TEXT 
  primary_bitstream_id	INTEGER REFERENCES Bitstream(bitstream_id)
);

CREATE INDEX bundle_mets_fk_idx ON Bundle(mets_bitstream_id);
CREATE INDEX bundle_primary_fk_idx ON Bundle(primary_bitstream_id);

-------------------------------------------------------
-- Item2Bundle table
-------------------------------------------------------
CREATE TABLE Item2Bundle
(
  id        INTEGER PRIMARY KEY,
  item_id   INTEGER REFERENCES Item(item_id),
  bundle_id INTEGER REFERENCES Bundle(bundle_id)
);

-- index by item_id
CREATE INDEX item2bundle_item_idx on Item2Bundle(item_id);

CREATE INDEX item2bundle_bundle_fk_idx ON Item2Bundle(bundle_id);

-------------------------------------------------------
-- Bundle2Bitstream table
-------------------------------------------------------
CREATE TABLE Bundle2Bitstream
(
  id           INTEGER PRIMARY KEY,
  bundle_id    INTEGER REFERENCES Bundle(bundle_id),
  bitstream_id INTEGER REFERENCES Bitstream(bitstream_id)
);

-- index by bundle_id
CREATE INDEX bundle2bitstream_bundle_idx ON Bundle2Bitstream(bundle_id);

CREATE INDEX bundle2bits_bitstream_fk_idx ON Bundle2Bitstream(bitstream_id);

-------------------------------------------------------
-- Metadata Tables and Sequences
-------------------------------------------------------
CREATE TABLE MetadataSchemaRegistry
(
  metadata_schema_id INTEGER PRIMARY KEY,
  namespace          VARCHAR(256) UNIQUE,
  short_id           VARCHAR(32) UNIQUE
);

CREATE TABLE MetadataFieldRegistry
(
  metadata_field_id   INTEGER PRIMARY KEY,
  metadata_schema_id  INTEGER NOT NULL REFERENCES MetadataSchemaRegistry(metadata_schema_id),
  element    VARCHAR(64),
  qualifier  VARCHAR(64),
  scope_note VARCHAR2(2000)
);

CREATE TABLE MetadataValue
(
  metadata_value_id  INTEGER PRIMARY KEY,
  item_id       INTEGER REFERENCES Item(item_id),
  metadata_field_id  INTEGER REFERENCES MetadataFieldRegistry(metadata_field_id),
  text_value CLOB,
  text_lang  VARCHAR(64),
  place              INTEGER
);

-- Create the DC schema
INSERT INTO MetadataSchemaRegistry VALUES (1,'http://dublincore.org/documents/dcmi-terms/','dc');

-- Create a dcvalue view for backwards compatibilty
CREATE VIEW dcvalue AS
  SELECT MetadataValue.metadata_value_id AS "dc_value_id", MetadataValue.item_id,
    MetadataValue.metadata_field_id AS "dc_type_id", MetadataValue.text_value,
    MetadataValue.text_lang, MetadataValue.place
  FROM MetadataValue, MetadataFieldRegistry
  WHERE MetadataValue.metadata_field_id = MetadataFieldRegistry.metadata_field_id
  AND MetadataFieldRegistry.metadata_schema_id = 1;

-- An index for item_id - almost all access is based on
-- instantiating the item object, which grabs all values
-- related to that item
CREATE INDEX metadatavalue_item_idx ON MetadataValue(item_id);
CREATE INDEX metadatavalue_item_idx2 ON MetadataValue(item_id,metadata_field_id);
CREATE INDEX metadatavalue_field_fk_idx ON MetadataValue(metadata_field_id);
CREATE INDEX metadatafield_schema_idx ON MetadataFieldRegistry(metadata_schema_id);

-------------------------------------------------------
-- Community table
-------------------------------------------------------
CREATE TABLE Community
(
  community_id      INTEGER PRIMARY KEY,
  name              VARCHAR2(128),
  short_description VARCHAR2(512),
  introductory_text CLOB,
  logo_bitstream_id INTEGER REFERENCES Bitstream(bitstream_id),
  copyright_text    CLOB,
  side_bar_text     VARCHAR2(2000),
  admin             INTEGER REFERENCES EPersonGroup( eperson_group_id )      
);

CREATE INDEX community_logo_fk_idx ON Community(logo_bitstream_id);
CREATE INDEX community_admin_fk_idx ON Community(admin);

-------------------------------------------------------
-- Collection table
-------------------------------------------------------
CREATE TABLE Collection
(
  collection_id     INTEGER PRIMARY KEY,
  name              VARCHAR2(128),
  short_description VARCHAR2(512),
  introductory_text CLOB,
  logo_bitstream_id INTEGER REFERENCES Bitstream(bitstream_id),
  template_item_id  INTEGER REFERENCES Item(item_id),
  provenance_description  VARCHAR2(2000),
  license           CLOB,
  copyright_text    CLOB,
  side_bar_text     VARCHAR2(2000),
  workflow_step_1   INTEGER REFERENCES EPersonGroup( eperson_group_id ),
  workflow_step_2   INTEGER REFERENCES EPersonGroup( eperson_group_id ),
  workflow_step_3   INTEGER REFERENCES EPersonGroup( eperson_group_id ),
  submitter         INTEGER REFERENCES EPersonGroup( eperson_group_id ),
  admin             INTEGER REFERENCES EPersonGroup( eperson_group_id )
);

CREATE INDEX collection_logo_fk_idx ON Collection(logo_bitstream_id);
CREATE INDEX collection_template_fk_idx ON Collection(template_item_id);
CREATE INDEX collection_workflow1_fk_idx ON Collection(workflow_step_1);
CREATE INDEX collection_workflow2_fk_idx ON Collection(workflow_step_2);
CREATE INDEX collection_workflow3_fk_idx ON Collection(workflow_step_3);
CREATE INDEX collection_submitter_fk_idx ON Collection(submitter);
CREATE INDEX collection_admin_fk_idx ON Collection(admin);

-------------------------------------------------------
-- Community2Community table
-------------------------------------------------------
CREATE TABLE Community2Community
(
  id             INTEGER PRIMARY KEY,
  parent_comm_id INTEGER REFERENCES Community(community_id),
  child_comm_id  INTEGER REFERENCES Community(community_id)
);

CREATE INDEX com2com_parent_fk_idx ON Community2Community(parent_comm_id);
CREATE INDEX com2com_child_fk_idx ON Community2Community(child_comm_id);

-------------------------------------------------------
-- Community2Collection table
-------------------------------------------------------
CREATE TABLE Community2Collection
(
  id             INTEGER PRIMARY KEY,
  community_id   INTEGER REFERENCES Community(community_id),
  collection_id  INTEGER REFERENCES Collection(collection_id)
);

-- Improve mapping tables
CREATE INDEX Comm2Coll_community_id_idx ON Community2Collection(community_id);
CREATE INDEX Comm2Coll_collection_id_idx ON Community2Collection(collection_id);

-------------------------------------------------------
-- Collection2Item table
-------------------------------------------------------
CREATE TABLE Collection2Item
(
  id            INTEGER PRIMARY KEY,
  collection_id INTEGER REFERENCES Collection(collection_id),
  item_id       INTEGER REFERENCES Item(item_id)
);

-- index by collection_id
CREATE INDEX collection2item_collection_idx ON Collection2Item(collection_id);

-- Improve mapping tables
CREATE INDEX Collection2Item_item_id_idx ON Collection2Item( item_id );

-------------------------------------------------------
-- ResourcePolicy table
-------------------------------------------------------
CREATE TABLE ResourcePolicy
(
  policy_id            INTEGER PRIMARY KEY,
  resource_type_id     INTEGER,
  resource_id          INTEGER,
  action_id            INTEGER,
  eperson_id           INTEGER REFERENCES EPerson(eperson_id),
  epersongroup_id      INTEGER REFERENCES EPersonGroup(eperson_group_id),
  start_date           DATE,
  end_date             DATE
);

-- index by resource_type,resource_id - all queries by
-- authorization manager are select type=x, id=y, action=z
CREATE INDEX resourcepolicy_type_id_idx ON ResourcePolicy(resource_type_id,resource_id); 

CREATE INDEX rp_eperson_fk_idx ON ResourcePolicy(eperson_id);
CREATE INDEX rp_epersongroup_fk_idx ON ResourcePolicy(epersongroup_id);

-------------------------------------------------------
-- EPersonGroup2EPerson table
-------------------------------------------------------
CREATE TABLE EPersonGroup2EPerson
(
  id               INTEGER PRIMARY KEY,
  eperson_group_id INTEGER REFERENCES EPersonGroup(eperson_group_id),
  eperson_id       INTEGER REFERENCES EPerson(eperson_id)
);

-- Index by group ID (used heavily by AuthorizeManager)
CREATE INDEX epersongroup2eperson_group_idx on EPersonGroup2EPerson(eperson_group_id);

CREATE INDEX epg2ep_eperson_fk_idx ON EPersonGroup2EPerson(eperson_id);


-------------------------------------------------------
-- Handle table
-------------------------------------------------------
CREATE TABLE Handle
(
  handle_id        INTEGER PRIMARY KEY,
  handle           VARCHAR2(256) UNIQUE,
  resource_type_id INTEGER,
  resource_id      INTEGER
);

-- index by resource id and resource type id
CREATE INDEX handle_resource_id_type_idx ON handle(resource_id, resource_type_id);

-------------------------------------------------------
--  WorkspaceItem table
-------------------------------------------------------
CREATE TABLE WorkspaceItem
(
  workspace_item_id INTEGER PRIMARY KEY,
  item_id           INTEGER REFERENCES Item(item_id),
  collection_id     INTEGER REFERENCES Collection(collection_id),
  -- Answers to questions on first page of submit UI
  multiple_titles   NUMBER(1),  -- boolean
  published_before  NUMBER(1),
  multiple_files    NUMBER(1),
  -- How for the user has got in the submit process
  stage_reached     INTEGER,
  page_reached      INTEGER
);

CREATE INDEX workspace_item_fk_idx ON WorkspaceItem(item_id);
CREATE INDEX workspace_coll_fk_idx ON WorkspaceItem(collection_id);

-------------------------------------------------------
--  WorkflowItem table
-------------------------------------------------------
CREATE TABLE WorkflowItem
(
  workflow_id    INTEGER PRIMARY KEY,
  item_id        INTEGER REFERENCES Item(item_id) UNIQUE,
  collection_id  INTEGER REFERENCES Collection(collection_id),
  state          INTEGER,
  owner          INTEGER REFERENCES EPerson(eperson_id),

  -- Answers to questions on first page of submit UI
  multiple_titles       NUMBER(1),
  published_before      NUMBER(1),
  multiple_files        NUMBER(1)
  -- Note: stage reached not applicable here - people involved in workflow
  -- can always jump around submission UI

);

CREATE INDEX workflow_coll_fk_idx ON WorkflowItem(collection_id);
CREATE INDEX workflow_owner_fk_idx ON WorkflowItem(owner);

-------------------------------------------------------
--  TasklistItem table
-------------------------------------------------------
CREATE TABLE TasklistItem
(
  tasklist_id	INTEGER PRIMARY KEY,
  eperson_id	INTEGER REFERENCES EPerson(eperson_id),
  workflow_id	INTEGER REFERENCES WorkflowItem(workflow_id)
);

CREATE INDEX tasklist_eperson_fk_idx ON TasklistItem(eperson_id);
CREATE INDEX tasklist_workflow_fk_idx ON TasklistItem(workflow_id);


-------------------------------------------------------
--  RegistrationData table
-------------------------------------------------------
CREATE TABLE RegistrationData
(
  registrationdata_id   INTEGER PRIMARY KEY,
  email                 VARCHAR2(64) UNIQUE,
  token                 VARCHAR2(48),
  expires		TIMESTAMP
);


-------------------------------------------------------
--  Subscription table
-------------------------------------------------------
CREATE TABLE Subscription
(
  subscription_id   INTEGER PRIMARY KEY,
  eperson_id        INTEGER REFERENCES EPerson(eperson_id),
  collection_id     INTEGER REFERENCES Collection(collection_id)
);

CREATE INDEX subs_eperson_fk_idx ON Subscription(eperson_id);
CREATE INDEX subs_collection_fk_idx ON Subscription(collection_id);


-------------------------------------------------------
--  History table
-------------------------------------------------------
CREATE TABLE History
(
  history_id           INTEGER PRIMARY KEY,
  -- When it was stored
  creation_date        TIMESTAMP,
  -- A checksum to keep INTEGERizations from being stored more than once
  checksum             VARCHAR2(32) UNIQUE
);

-------------------------------------------------------
--  HistoryState table
-------------------------------------------------------
CREATE TABLE HistoryState
(
  history_state_id           INTEGER PRIMARY KEY,
  object_id                  VARCHAR2(64)
);

-------------------------------------------------------------------------------
-- EPersonGroup2WorkspaceItem table
-------------------------------------------------------------------------------

CREATE TABLE EPersonGroup2WorkspaceItem 
(
  id INTEGER PRIMARY KEY,
  eperson_group_id INTEGER REFERENCES EPersonGroup(eperson_group_id),
  workspace_item_id INTEGER REFERENCES WorkspaceItem(workspace_item_id)
);

CREATE INDEX epg2wi_group_fk_idx ON epersongroup2workspaceitem(eperson_group_id);
CREATE INDEX epg2wi_workspace_fk_idx ON epersongroup2workspaceitem(workspace_item_id);

------------------------------------------------------------
-- Browse subsystem tables and views
------------------------------------------------------------

-------------------------------------------------------
--  Communities2Item table
-------------------------------------------------------
CREATE TABLE Communities2Item
(
   id                      INTEGER PRIMARY KEY,
   community_id            INTEGER REFERENCES Community(community_id),
   item_id                 INTEGER REFERENCES Item(item_id)
);

-- Indexing browse tables update/re-index performance
CREATE INDEX Communities2Item_item_id_idx ON Communities2Item( item_id );
CREATE INDEX Comm2Item_community_fk_idx ON Communities2Item( community_id );

-------------------------------------------------------
-- Community2Item view
------------------------------------------------------
CREATE VIEW Community2Item as
SELECT Community2Collection.community_id, Collection2Item.item_id 
FROM Community2Collection, Collection2Item
WHERE Collection2Item.collection_id   = Community2Collection.collection_id
;

-------------------------------------------------------------------------
-- Tables to manage cache of item counts for communities and collections
-------------------------------------------------------------------------

CREATE TABLE collection_item_count (
	collection_id INTEGER PRIMARY KEY REFERENCES collection(collection_id),
	count INTEGER
);

CREATE TABLE community_item_count (
	community_id INTEGER PRIMARY KEY REFERENCES community(community_id),
	count INTEGER
);

-------------------------------------------------------
--  Create 'special' groups, for anonymous access
--  and administrators
-------------------------------------------------------
-- We don't use getnextid() for 'anonymous' since the sequences start at '1'
INSERT INTO epersongroup VALUES(0, 'Anonymous');
INSERT INTO epersongroup VALUES(1, 'Administrator');


-------------------------------------------------------
-- Create the checksum checker tables
-------------------------------------------------------
-- list of the possible results as determined
-- by the system or an administrator

CREATE TABLE checksum_results
(
    result_code VARCHAR(64) PRIMARY KEY,
    result_description VARCHAR2(2000)
);


-- This table has a one-to-one relationship
-- with the bitstream table. A row will be inserted
-- every time a row is inserted into the bitstream table, and
-- that row will be updated every time the checksum is
-- re-calculated.

CREATE TABLE most_recent_checksum 
(
    bitstream_id INTEGER PRIMARY KEY REFERENCES bitstream(bitstream_id),
    to_be_processed NUMBER(1) NOT NULL,
    expected_checksum VARCHAR(64),
    current_checksum VARCHAR(64),
    last_process_start_date TIMESTAMP NOT NULL,
    last_process_end_date TIMESTAMP NOT NULL,
    checksum_algorithm VARCHAR(64) NOT NULL,
    matched_prev_checksum NUMBER(1) NOT NULL,
    result VARCHAR(64) REFERENCES checksum_results(result_code)
);

CREATE INDEX mrc_result_fk_idx ON most_recent_checksum( result );

-- A row will be inserted into this table every
-- time a checksum is re-calculated.

CREATE SEQUENCE checksum_history_seq;

CREATE TABLE checksum_history 
(
    check_id INTEGER PRIMARY KEY,
    bitstream_id INTEGER,
    process_start_date TIMESTAMP,
    process_end_date TIMESTAMP,
    checksum_expected VARCHAR(64),
    checksum_calculated VARCHAR(64),
    result VARCHAR(64) REFERENCES checksum_results(result_code)
);

CREATE INDEX ch_result_fk_idx ON checksum_history( result );


-- this will insert into the result code
-- the initial results that should be 
-- possible

insert into checksum_results
values
( 
    'INVALID_HISTORY',
    'Install of the cheksum checking code do not consider this history as valid' 
);

insert into checksum_results
values
( 
    'BITSTREAM_NOT_FOUND',
    'The bitstream could not be found' 
);

insert into checksum_results
values
( 
    'CHECKSUM_MATCH',
    'Current checksum matched previous checksum' 
);

insert into checksum_results
values
(
    'CHECKSUM_NO_MATCH',
    'Current checksum does not match previous checksum' 
);

insert into checksum_results
values
( 
    'CHECKSUM_PREV_NOT_FOUND',
    'Previous checksum was not found: no comparison possible' 
);

insert into checksum_results
values
( 
    'BITSTREAM_INFO_NOT_FOUND',
    'Bitstream info not found' 
);

insert into checksum_results
values
( 
    'CHECKSUM_ALGORITHM_INVALID',
    'Invalid checksum algorithm' 
);
insert into checksum_results
values
( 
    'BITSTREAM_NOT_PROCESSED',
    'Bitstream marked to_be_processed=false' 
);
insert into checksum_results
values
( 
    'BITSTREAM_MARKED_DELETED',
    'Bitstream marked deleted in bitstream table' 
);