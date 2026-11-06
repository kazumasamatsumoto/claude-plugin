// サンプル用の小さなモジュール（エージェントやスキルの動作確認用）
export function add(a, b) {
  return a + b;
}

export function divide(a, b) {
  // TODO: 0 除算時のエラーメッセージを整える
  if (b === 0) throw new Error("division by zero");
  return a / b;
}
