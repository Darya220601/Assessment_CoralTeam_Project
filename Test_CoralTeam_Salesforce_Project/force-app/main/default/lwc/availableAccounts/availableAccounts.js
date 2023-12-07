import { LightningElement, wire, track } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext, releaseMessageContext } from 'lightning/messageService';
import ACCOUNT_CONTACT_CHANNEL from '@salesforce/messageChannel/AccountsMessageChannel__c';
import getAccountContactTree from '@salesforce/apex/AccountController.getAccountContactTree';
import getUserPermissionSetNames from '@salesforce/apex/AccountController.getUserPermissionSetNames';

const ERROR_TITLE   = 'Error';
const ERROR_VARIANT = 'error';
const NO_ACCOUNTS_MESSAGE = 'You have Business permissions, but there are no available accounts.';
const BUSINESS_USER = 'business';


export default class AvailableAccounts extends LightningElement {
    @track treeItems = [];
    @track selectedItem = null;
    error;
    errorMessage;
    UserPermission = null;

    @wire(MessageContext)
    messageContext;

    @wire(getAccountContactTree)
    wiredTree({ error, data }) {
        if (data) {
            this.treeItems = data;
            console.log(this.treeItems);
        } else if (error) {
            console.log(error);
            this.error = error;
            this.errorMessage = reduceErrors(this.error);
            this.showNotification();
        }
    }

    connectedCallback() {
        getUserPermissionSetNames()
            .then(result => {
                this.UserPermission = result;
                console.log(this.UserPermission);
                console.log('User Permission Set Information:', result);
            })
            .catch(error => {
                console.error('Error fetching user permission set information:', error);
            });
    }

    handleTreeSelect(event) {
        this.selectedItem = event.detail;
        console.log('Selected Item:', this.selectedItem);
        this.publishLMS();
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

    publishLMS() {
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

    get hasNoAccounts() {
        return (
            this.treeItems.length === 0  &&
            this.UserPermission === BUSINESS_USER
        );    
    }

    get noAccountsMessage() {
        return NO_ACCOUNTS_MESSAGE;
    }

    showNotification() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ERROR_TITLE,
                message: this.errorMessage.toString(),
                variant: ERROR_VARIANT
            })
        );
    }

    disconnectedCallback() {
        releaseMessageContext(this.messageContext);
    }
}
