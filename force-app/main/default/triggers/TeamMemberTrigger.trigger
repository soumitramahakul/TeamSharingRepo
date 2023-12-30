trigger TeamMemberTrigger on Team_Member__c (after insert,after update,after delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert  || Trigger.isUpdate){
            System.enqueueJob(new TeamMemberTriggerHelper(Trigger.oldMap,Trigger.newMap));
        }
        if(Trigger.isDelete){
            System.enqueueJob(new TeamMemberDelete(Trigger.old));
        }
    }
}