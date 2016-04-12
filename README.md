# CleanSCCMADRGroups

To deploy definitions (such as Antivirus defitions for SCEP), the feature within SCCM called Automatic Deployment Rules (ADR) must be used. This is used to automatically approve, download and deploy updates matching specific criteria. Once new updates are synchronized from Microsoft, SCCM will create a new Software Update Group (SUG) and deploy these updates to the specified collection(s). 

SCCM 2012 R2 will automatically remove updates that are expired and orphaned (not apart of any SUG), there is however, no process for removing the SUGs that only contain expired updates. If the SUGs that only contain expired updates are not deleted, then the expired updates will never be removed by SCCM. This script will search for any ADR created rule that only contains expired updates and deletes it. It will leave the actual removal of the expire updates to the normal builtin SCCM maintenance tasks.  
