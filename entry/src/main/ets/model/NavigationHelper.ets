import { BusinessError } from '@kit.BasicServicesKit';

export function pushPage(ctx: UIContext, url: string): void {
  ctx.getRouter().pushUrl({ url: url }).catch((e: BusinessError) => {
    console.error(`Navigation push failed: ${e.code} ${e.message}`);
  });
}

export function backPage(ctx: UIContext): void {
  try {
    ctx.getRouter().back();
  } catch (e) {
    const err = e as BusinessError;
    console.error(`Navigation back failed: ${err.code} ${err.message}`);
  }
}

export function showInfoDialog(ctx: UIContext, title: string, message: string): void {
  ctx.showAlertDialog({
    title: title,
    message: message,
    confirm: { value: '知道了', action: () => {} }
  });
}
