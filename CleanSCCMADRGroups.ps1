<# 
.SYNOPSIS 
	Deletes SCCM ADR Created Software Update Groups that contain only expired updates.
.DESCRIPTION 
	Deletes SCCM ADR Created Software Update Groups that contain only expired updates. 
	To deploy security definitions (Endpoint protection, etc), SCCM Uses Automatic Deployment Rules (ADR). These rules automatically create a software update group and deploy it to collections.
	These updates consume space and are expired quickly (within a day or 2). SCCM will automatically clean expired/superceded updates that are orphaned (no longer in a Software Update Group) or otherwise deployed.
	There is, however, no process to remove the update groups. This script removes ADR created Software Update Groups that contain only expired updates. The updates that were in this group should be cleaned by SCCM automatically.
	wsyncmgr.log file contains information when SCCM cleans orphaned/expired updates.
.NOTES 
    File Name  : CleanSCCMADRGroups.ps1
    Author     : Brenton keegan - brenton.keegan@gmail.com 
    Licenced under GPLv3  
.LINK 
	https://github.com/bkeegan/CleanSCCMADRGroups
    License: http://www.gnu.org/copyleft/gpl.html
	Cmdlet Library: https://www.microsoft.com/en-us/download/details.aspx?id=46681
.EXAMPLE 
	CleanSCCMADRGroups -s "SiteCode" -srv "sms.contoso.com" -to "reports@contoso.com" -from "reports@contoso.com" -smtp "mail.contoso.com"

#> 

#imports
import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Function CleanSCCMADRGroups
{
	[cmdletbinding()]
		Param
		(
			[parameter(Mandatory=$true)]
			[alias("s")]
			[string]$smsSiteCode,
			
			[parameter(Mandatory=$true)]
			[alias("srv")]
			[string]$smsSiteServer,
			
			[parameter(Mandatory=$true)]
			[alias("To")]
			[string]$emailRecipient,
			
			[parameter(Mandatory=$true)]
			[alias("From")]
			[string]$emailSender,
			
			[parameter(Mandatory=$true)]
			[alias("smtp")]
			[string]$emailServer,
			
			[parameter(Mandatory=$false)]
			[alias("Subject")]
			[string]$emailSubject="SMS ADR Cleanup Report",
			
			[parameter(Mandatory=$false)]
			[alias("body")]
			[string]$emailBody="SMS ADR Cleanup Report - See Attachment"
		)


	#variable init
	$smsPathLocation = "$smsSiteCode" + ":\" #name os PSDrive to set location to to issue SCCM cmdlets
	#if the PSdrive does not exist with the sitecode, create it (this may occur if the script is running as NT Authority\System)
	If(!(Get-PSDrive | where {$_.Name -eq $smsSiteCode}))
	{
		New-PSDrive -Name $smsSiteCode -PSProvider "CMSite" -root $smsSiteServer
	}
	Set-Location $smsPathLocation #set location of SMS Site
	$sccmADRCleanResults = new-object 'system.collections.generic.dictionary[string,string]'	#dictionary object to store results
	[string]$dateStamp = Get-Date -UFormat "%Y%m%d_%H%M%S" #timestamp for naming report
	$tempFolder = get-item env:temp #temp folder
	
	#get update groups where the total number of updates in the group is equal to the total number of expired updates in the group (contains only expired updates) and the createdby value is "AutoUpdateRuleEngine"
	$expiredADRGroups = Get-CMSoftwareUpdateGroup | where {$_.NumberOfUpdates -eq $_.NumberOfExpiredUpdates -and $_.CreatedBy -eq "AutoUpdateRuleEngine"}
	Foreach($expiredADRGroup in $expiredADRGroups)
	{
		$deleteFailed = $false
		Try
		{
			#delete the group 
			$expiredADRGroup.Delete()
		}
		Catch
		{
			#if delete failed - record results
			$deleteFailed = $true
			$sccmADRCleanResults.Add($expiredADRGroup.LocalizedDisplayName,"Delete Failed")
		}
		if(!($deleteFailed))
		{
			#if delete was successful - record results
			$sccmADRCleanResults.Add($expiredADRGroup.LocalizedDisplayName,"Delete Successful")
		}
		
	
	}
	
	
	#generate HTML Report
	$sccmADRCleanResults.GetEnumerator() | Sort-Object -property Value | ConvertTo-HTML | Out-File "$($tempFolder.value)\$dateStamp-SCCMADRRulesReport.html"
	#send email to specified recipient and attach HTML report
	Send-MailMessage -To $emailRecipient -Subject $emailSubject -smtpServer $emailServer -From $emailSender -body $emailBody -Attachments "$($tempFolder.value)\$dateStamp-SCCMADRRulesReport.html"
	
}
