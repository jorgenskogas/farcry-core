<!--- @@Copyright: Daemon Pty Limited 2002-2008, http://www.daemon.com.au --->
<!--- @@License:
    This file is part of FarCry.

    FarCry is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    FarCry is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with FarCry.  If not, see <http://www.gnu.org/licenses/>.
--->
<!---
|| VERSION CONTROL ||
$Header: /cvs/farcry/core/packages/types/dmNavigation.cfc,v 1.20.2.11 2006/03/08 00:32:13 paul Exp $
$Author: paul $
$Date: 2006/03/08 00:32:13 $
$Name: milestone_3-0-1 $
$Revision: 1.20.2.11 $

|| DESCRIPTION || 
$Description: dmNavigation type $


|| DEVELOPER ||
$Developer: Brendan Sisson (brendan@daemon.com.au) $

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfcomponent name="dmNavigation" extends="types" displayname="Navigation" hint="Navigation nodes are combined with the ntm_navigation table to build the site layout model for the FarCry CMS system." bUseInTree="1" bFriendly="1" bObjectBroker="true">
	<!------------------------------------------------------------------------
	type properties
	------------------------------------------------------------------------->	
	<cfproperty ftSeq="1" ftFieldSet="General Details" name="title" type="nstring" hint="Object title.  Same as Label, but required for overview tree render." required="no" default="" ftLabel="Title" />
	
	<cfproperty ftSeq="5" ftFieldSet="Advanced" name="lNavIDAlias" type="string" hint="A Nav alias provides a human interpretable link to this navigation node.  Each Nav alias is set up as key in the structure application.navalias.<i>aliasname</i> with a value equal to the navigation node's UUID." required="no" default="" ftLabel="Alias" />
	<cfproperty ftSeq="10" ftFieldSet="Advanced" name="ExternalLink" type="string" hint="URL to an external (ie. off site) link." required="no" default="" ftType="list" ftLabel="Redirect to" ftListData="getExternalLinks" />
	
	<cfproperty name="fu" type="string" hint="Friendly URL for this node." required="no" default="" ftLabel="Friendly URL" />
	<cfproperty name="aObjectIDs" type="array" hint="Holds objects to be displayed at this particular node.  Can be of mixed types." required="no" default="" ftJoin="dmImage" />
	<cfproperty name="options" type="string" hint="No idea what this is for." required="no" default="" ftLabel="Options" />
	<cfproperty name="status" type="string" hint="Status of the node (draft, pending, approved)." required="yes" default="draft" ftLabel="Status" />
	
	<!------------------------------------------------------------------------
	object methods 
	------------------------------------------------------------------------->
	<cffunction name="getExternalLinks" access="public" returntype="query" output="false" hint="Returns a list of all navigation nodes in the system with an alias">
	
		<cfset var oNav = createObject("component", application.stcoapi["dmNavigation"].packagePath) />
		<cfset var i = "" />
		<cfset var j = "" />
		<cfset var q = queryNew("value,name") />
		
		<cfset queryaddrow(q,1) />
		<cfset querysetcell(q, "value", "") />
		<cfset querysetcell(q, "name", "#application.rb.getResource('coapi.dmNavigation.properties.externallink@nooptions','-- None --')#") />
		
		<cfloop collection="#application.navid#" item="i">
			<cfloop list="#application.navid[i]#" index="j">
				<cfset stNav = oNav.getData(objectid="#j#") />
				<cfset queryaddrow(q,1) />
				<cfset querysetcell(q, "value", j) />
				<cfset querysetcell(q, "name", "#stNav.title# (#i#)") />	
			</cfloop>		
		</cfloop>
		
		<cfquery dbtype="query" name="q">
		SELECT *
		FROM q
		ORDER BY name
		</cfquery>

		<cfreturn q />
	</cffunction>
	
	
	
	<cffunction name="AfterSave" access="public" output="true" returntype="struct" hint="Called from ProcessFormObjects and run after the object has been saved.">
		<cfargument name="stProperties" required="yes" type="struct" hint="A structure containing the contents of the properties that were saved to the object.">
		
		<cflock scope="Application" timeout="20">
			<cfset application.navid = getNavAlias()>
		</cflock>
		
		<cfif structKeyExists(stProperties, "title")>
			<cfquery datasource="#application.dsn#">
			UPDATE #application.dbowner#nested_tree_objects 
			SET objectName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stProperties.title#">
			WHERE objectID = '#stProperties.ObjectID#'
			</cfquery>
		</cfif>
		
		<cfreturn stProperties />
	</cffunction>
			
				
	
	<cffunction name="getParent" access="public" returntype="query" output="false" hint="Returns the navigation parent of child (dmHTML page for example)">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of element needing a parent">
		<cfargument name="dsn" required="yes" type="string" default="#application.dsn#">
		
		<cfquery name="qGetParent" datasource="#arguments.dsn#">
			SELECT parentid FROM #application.dbowner#dmNavigation_aObjectIDs
			WHERE data = '#arguments.objectid#'	
		</cfquery>
		
		<cfreturn qGetParent>
	</cffunction>
	
	<cffunction name="getChildren" access="public" returntype="query" output="false" hint="Returns the navigation children (dmHTML page for example)">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of children's parent to be returned">
		<cfargument name="dsn" required="yes" type="string" default="#application.dsn#">
		<cfargument name="status" required="no" type="string" default="approved">
			<cfset var o = createObject("component", "#application.packagepath#.farcry.tree")>
			<cfset var navFilter=arrayNew(1)>
			<cfset navfilter[1]="status = '#arguments.status#'">
			<cfset qNav = o.getDescendants(objectid=arguments.objectid, lColumns='title,lNavIDAlias, status', depth=1, afilter=navfilter)>
		<cfreturn qNav>
	</cffunction>
	
	<cffunction name="getSiblings" access="public" returntype="query" output="false" hint="Returns the sibblings of a node navigation ">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of children's parent to be returned">
		<cfargument name="dsn" required="yes" type="string" default="#application.dsn#">
		<cfargument name="status" required="no" type="string" default="approved">
			<cfset var o = createObject("component", "#application.packagepath#.farcry.tree")>
			<cfset var navFilter=arrayNew(1)>
			<cfset navfilter[1]="status = '#arguments.status#'">
			<cfset qNav = o.getDescendants(objectid=arguments.objectid, lColumns='title,lNavIDAlias, status', depth=0, afilter=navfilter)>
		<cfreturn qNav>
	</cffunction>
	
	
	<cffunction name="delete" access="public" hint="Specific delete method for dmNavigation. Removes all descendants">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the object being deleted">
		<cfargument name="dsn" required="yes" type="string" default="#application.dsn#">
		
		<!--- get object details --->
		<cfset var stObj = getData(arguments.objectid)>
		
		<cfset var oHTML = createObject("component", application.stcoapi.dmHTML.packagePath) />
		<cfset var stHTML = structNew() />
		<cfset var qRelated = queryNew("blah") />
		<cfset var qDeleteRelated = queryNew("blah") />
		
		<cfset var stReturn = StructNew()>
		
		<cfif NOT structIsEmpty(stObj)>
			<cfinclude template="_dmNavigation/delete.cfm">
			
			<!--- Find any dmHTML pages that reference this navigation node. --->
			<cfquery datasource="#application.dsn#" name="qRelated">
			SELECT * FROM dmHTML_aRelatedIDs
			WHERE data = '#stobj.objectid#'
			</cfquery>
			
			<cfif qRelated.recordCount>
	
				<!--- Delete any of these relationships --->
				<cfquery datasource="#application.dsn#" name="qDeleteRelated">
				DELETE FROM dmHTML_aRelatedIDs
				WHERE data = '#stobj.objectid#'
				</cfquery>
							
				<!--- Loop over and refresh the object broker if required --->
				<cfloop query="qRelated">
					<cfset stHTML = oHTML.getData(objectid=qRelated.parentid, bUseInstanceCache=false) />				
				</cfloop>		
							
			</cfif>
			
			<cfset stReturn.bSuccess = true>
			<cfset stReturn.message = "#stObj.label# (#stObj.typename#) deleted.">
			<cfreturn stReturn>
		<cfelse>
			
			<cfset stReturn.bSuccess = false>
			<cfset stReturn.message = "#arguments.objectid# (dmNavigation) not found.">
			<cfreturn stReturn>
		
		</cfif>
	</cffunction>
	
	<cffunction name="getNavAlias" access="public" hint="Return a structure of all the dmNavigation nodes with aliases." returntype="struct" output="false">
		<cfargument name="dsn" required="yes" type="string" default="#application.dsn#">
	
		<cfset var stResult = structNew()>
		<cfset var q = "">
	
		<!--- $TODO: all app vars should be passed in as arguments! 
		move application.dbowner (and others no doubt) GB$ --->
		<cfquery datasource="#arguments.dsn#" name="q">
		SELECT nav.objectID, nav.lNavIDAlias, ntm.nLeft
		FROM	#application.dbowner#dmNavigation nav, 
				#application.dbowner#nested_tree_objects ntm
		WHERE	nav.objectid = ntm.objectid
		AND lNavIDAlias <> ''
		AND lNavIDAlias IS NOT NULL
		ORDER BY ntm.nLeft
		</cfquery>
	
		<cfloop query="q">
			<cfscript>
				if(len(q.lNavIdAlias))
				{
					for( i=1; i le ListLen(q.lNavIdAlias); i=i+1 )
					{
						alias = Trim(ListGetAt(q.lNavIdAlias,i));
						if (NOT StructKeyExists(stResult, alias)) {
							stResult[alias] = q.objectID;
						} else { 
							//stResult[alias] = ListAppend(stResult[alias], q.objectID);
						}
					}
				}
			</cfscript>
		</cfloop>
		<cfreturn stResult>
	</cffunction>
	
	<cffunction name="renderOverview" access="public" hint="Renders options available on the overview page" output="false">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the selected object">
		
		<!--- get object details --->
		<cfset stObj = getData(arguments.objectid)>
		
		<cfinclude template="_dmNavigation/renderOverview.cfm">
		
		<cfreturn html>
	</cffunction>
	
	<cffunction name="renderObjectOverview" access="public" hint="Renders entire object overiew" output="true">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the selected object">
			
		<!--- get object details --->
		<cfset var stObj = getData(arguments.objectid)>
		<cfset var stLocal = StructNew()>
		<cfset stLocal.html = "">		
		<cfinclude template="_dmNavigation/renderObjectOverview.cfm">
		<cfreturn stLocal.html>
	
	</cffunction>
	
	<cffunction name="buildTreeCreateTypes" access="public" returntype="array" hint="Creates array of content types that can be created" output="false">
		<cfargument name="lTypes" required="true" type="string">
	
		<cfset var aReturn = ArrayNew(1)>
		<cfset var aTypes = listToArray(arguments.lTypes)>
	
		<!--- build core types first --->
		<cfloop index="i" from="1" to="#arrayLen(aTypes)#">
			<cfif structKeyExists(Application.types[aTypes[i]],"bUseInTree")
				  AND Application.types[aTypes[i]].bUseInTree
				  AND NOT (structKeyExists(Application.types[aTypes[i]],"bCustomType")
						   AND Application.types[aTypes[i]].bCustomType)>
				<cfset ArrayAppend(aReturn, descriptionStructForType(aTypes[i])) />
			</cfif>
		</cfloop>
	
		<!--- then custom types --->
		<cfloop index="i" from="1" to="#arrayLen(aTypes)#">
			<cfif structKeyExists(Application.types[aTypes[i]],"bUseInTree")
				  AND Application.types[aTypes[i]].bUseInTree
				  AND structKeyExists(Application.types[aTypes[i]],"bCustomType")
				  AND Application.types[aTypes[i]].bCustomType>
				<cfset ArrayAppend(aReturn, descriptionStructForType(aTypes[i])) />
			</cfif>
		</cfloop>
		
		<cfreturn aReturn />
	</cffunction>
	
	<cffunction name="descriptionStructForType" access="private" returntype="struct">
		<cfargument name="typeName" type="string" required="true" />
		<cfset var stType = structNew()>
		<cfset stType.typename = arguments.typeName />
		<cfif structKeyExists(application.types[arguments.typename], "displayname")>
			<cfset stType.description = application.types[arguments.typename].displayName />
		<cfelse>
			<cfset stType.description = arguments.typeName />
		</cfif>
		<cfreturn stType />
	</cffunction>

	<cffunction name="ftEditaObjectIDs" access="public" returntype="string" description="This will return a string of formatted HTML text to enable the editing of the property" output="false">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var html = "" />
		<cfset var qTypes = querynew("typename,description","varchar,varchar") />
		<cfset var thistype = "" />
		
		<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
		
		<cfloop list="#structkeylist(application.stcoapi)#" index="thistype">
			<cfif structkeyexists(application.stCOAPI[thistype],"bUseInTree") and application.stCOAPI[thistype].bUseInTree>
				<cfif thistype NEQ "dmNavigation">
					<cfset queryaddrow(qTypes) />
					<cfset querysetcell(qTypes,"typename",thistype) />
					<cfif structkeyexists(application.stCOAPI[thistype],"displayname") and len(application.stCOAPI[thistype].displayname)>
						<cfset querysetcell(qTypes,"description",application.stCOAPI[thistype].displayname) />
					<cfelse>
						<cfset querysetcell(qTypes,"description",thistype) />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<cfquery dbtype="query" name="qTypes">
			select		*
			from		qTypes
			order by	description
		</cfquery>
		
		<cfif qTypes.recordcount>
			<cfsavecontent variable="html">
				<cfoutput>
					<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value=" " />
					<select name="#arguments.fieldname#typename" id="#arguments.fieldname#typename">
						<option value="">#application.rb.getResource("coapi.dmNavigation.properties.aObjectIDs@noneForSelect","-- None --")#</option>
						<cfloop query="qTypes">
							<option value="#qTypes.typename#">#qTypes.description#</option>
						</cfloop>	
					</select><br/>
				</cfoutput>
			</cfsavecontent>
		<cfelse>
			<cfsavecontent variable="html">
				<cfoutput>
					<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value=" " />
					<input type="hidden" name="#arguments.fieldname#typename" id="#arguments.fieldname#typename" value="" />
					<div>No types available</div>
				</cfoutput>
			</cfsavecontent>
		</cfif>
		
		<cfreturn html>
	</cffunction>

	<cffunction name="ftValidateaObjectIDs" access="public" output="true" returntype="struct" hint="This will return a struct with bSuccess and stError">
		<cfargument name="stFieldPost" required="true" type="struct" hint="The fields that are relevent to this field type.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		

		<cfset var stResult = structnew() />
		<cfset var stChild = structnew() />
		<cfset var oType = "" />
		
		<cfset stResult.value = arraynew(1) />
		<cfset stResult.bSuccess = true />
		<cfset stResult.stError = structNew() />
		<cfset stResult.stError.message = "" />
		<cfset stResult.stError.class = "" />
		
		<!--- --------------------------- --->
		<!--- Perform any validation here --->
		<!--- --------------------------- --->
		
		<cfif structkeyexists(arguments.stFieldPost.stSupporting,"typename")>
			<cfif len(arguments.stFieldPost.stSupporting.typename)>
				<cfset oType = createobject("component",application.stCOAPI[arguments.stFieldPost.stSupporting.typename].packagepath) />
				<cfset stChild = oType.getData(objectid=application.fc.utils.createJavaUUID()) />
				<cfset oType.setData(stProperties=stChild,bSessionOnly=true) />
				
				<cfset arrayappend(stResult.value,stChild.objectid) />
			</cfif>
		<cfelse>
			<cfset stResult.stError.class = "validation-advice" />
			<cfset stResult.stError.message = "The necessary fields were not present" />
		</cfif>
			
		<!--- ----------------- --->
		<!--- Return the Result --->
		<!--- ----------------- --->
		<cfreturn stResult>
	</cffunction>

</cfcomponent>