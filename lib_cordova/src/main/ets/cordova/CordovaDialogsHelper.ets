export class CordovaDialogsHelper {
  showAlert(event?: OnAlertEvent): void {
    if (event) {
      AlertDialog.show({
        title: 'Alert',
        message: event.message,
        primaryButton: {
          value: 'cancel',
          action: () => {
            event.result.handleCancel();
          }
        },
        secondaryButton: {
          value: 'ok',
          action: () => {
            event.result.handleConfirm();
          }
        },
        cancel: () => {
          event.result.handleCancel();
        }
      })
    }
  }

  showConfirm(event?: OnConfirmEvent): void {
    if (event) {
      AlertDialog.show({
        title: 'Confirm',
        message: event.message,
        primaryButton: {
          value: 'cancel',
          action: () => {
            event.result.handleCancel();
          }
        },
        secondaryButton: {
          value: 'ok',
          action: () => {
            event.result.handleConfirm();
          }
        },
        cancel: () => {
          event.result.handleCancel();
        }
      })
    }
  }

  showPrompt(event?: OnPromptEvent): void {
    if (event) {
      AlertDialog.show({
        title: 'Prompt',
        message: event.message,
        primaryButton: {
          value: 'cancel',
          action: () => {
            event.result.handleCancel();
          }
        },
        secondaryButton: {
          value: 'ok',
          action: () => {
            event.result.handlePromptConfirm(event.value);
          }
        },
        cancel: () => {
          event.result.handleCancel();
        }
      })
    }
  }
}