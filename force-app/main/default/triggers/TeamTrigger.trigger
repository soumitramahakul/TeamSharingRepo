trigger TeamTrigger on Team__c (After insert,After update,Before delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert  || Trigger.isUpdate){
            TeamTriggerHelper.CreateGroup(Trigger.oldMap,Trigger.newMap);
        }
    }
    if(Trigger.isBefore && Trigger.isDelete){
        System.enqueueJob(new GenericGroupDelete(Trigger.oldMap));
    }
}