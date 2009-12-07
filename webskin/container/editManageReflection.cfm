<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Manage container mirroring --->

<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/extjs" prefix="extjs" />

<cfset containerID = replace(stobj.objectid,'-','','ALL') />

<ft:processform action="Save">
	<cfif Trim(form.reflectionid) EQ ""> <!--- delete the reflection id --->
		<cfset deleteReflection(objectid=stObj.objectid) />
	<cfelse> <!--- set the reflection id --->
		<cfset setReflection(objectid=stObj.objectid,mirrorid=form.reflectionid) />
	</cfif>
	<cfset stObj.mirrorID = Trim(form.reflectionid)>
	<cfset setData(stproperties=stObj)>
</ft:processform>

<ft:processform action="Save,Cancel" bHideForms="true">
	<skin:onReady>
		<cfoutput>parent.location=parent.location;</cfoutput>	
	</skin:onReady>
</ft:processform>



<ft:form>

	<cfset qListReflections = getSharedContainers() />
	
	<cfoutput>
		
		<fieldset class="fieldset">
			
			<div class="ctrlHolder inlineLabels">
				<label class="label" for="reflectionid"> Select Reflection : </label>
				
				<select name="reflectionid" id="reflectionid" class="selectInput">
					<option value=""<cfif stObj.mirrorid EQ ""> selected="selected"</cfif>>Not reflected</option>
					<cfloop query="qListReflections">
						<option value="#qListReflections.objectid#"<cfif stObj.mirrorid EQ qListReflections.objectid> selected="selected"</cfif>>#qListReflections.label#</option>
					</cfloop>
				</select>
				
				<p class="formHint">Select the container you wish to reflect. This means that you will be using the container selected here instead of the container that would ordinarily be shown. </p>
			</div>
		</fieldset>
	</cfoutput>
	
	<ft:buttonPanel indentForLabel="true">
		<ft:button value="Save" />
		<ft:button value="Cancel" />
	</ft:buttonPanel>
</ft:form>


<cfsetting enablecfoutputonly="false" />