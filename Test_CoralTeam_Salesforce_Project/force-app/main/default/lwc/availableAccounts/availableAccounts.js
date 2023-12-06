import { LightningElement, wire } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import ACCOUNT_CONTACT_CHANNEL from '@salesforce/messageChannel/AccountsMessageChannel__c';
import getAccountContactTree from '@salesforce/apex/AccountController.getAccountContactTree';

const ERROR_TITLE   = 'Error';
const ERROR_VARIANT = 'error';

export default class AvailableAccounts extends LightningElement {
    treeItems = [];
    selectedItem = null;
    error;

    @wire(MessageContext)
    messageContext;

    @wire(getAccountContactTree)
    wiredTree({ error, data }) {
        if (data) {
            this.treeItems = data;
            console.log('data is exists');
            console.log(this.treeItems);
        } else if (error) {
            console.log(error);
            this.error = error;
            this.errorMessage = reduceErrors(this.error);
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: ERROR_TITLE,
                     message: this.errorMessage.toString(),
                     variant: ERROR_VARIANT
                 })
             );
        }
    }

    handleTreeSelect(event) {
        this.selectedItem = event.detail;
        console.log('Selected Item:', this.selectedItem);

        const matchingItem = this.findMatchingItem(this.selectedItem.name, this.treeItems);

        if (matchingItem) {
            const message = {
                recordId: matchingItem.name,
                type: matchingItem.type
            };
            console.log('Matching Item Type:', matchingItem.name);
            console.log('Matching Item Type:', matchingItem.type);
            publish(this.messageContext, ACCOUNT_CONTACT_CHANNEL, message);
        }
    }    
    
    findMatchingItem(name, items) {
        for (const item of items) {
            if (item.name === name) {
                return item;
            } else if (item.items) {
                const matchingItem = this.findMatchingItem(name, item.items);
                if (matchingItem) {
                    return matchingItem;
                }
            }
        }
        return null;
    }
}
