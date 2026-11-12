export const state = {
  currentLang: localStorage.getItem('ewr_lang') || 'id',
  currentTheme: localStorage.getItem('ewr_theme') || 'dark',
  currentStatusData: null
};

export function getSelectedTarget(el) {
  const selectedVal = el.selectDevice.value;
  const modelOverride = el.inputModelOverride.value.trim();

  const target = {
    model: modelOverride || null,
    interface: null,
    ip: null
  };

  if (selectedVal.startsWith('usb:')) {
    target.interface = parseInt(selectedVal.split(':')[1], 10);
  } else if (selectedVal.startsWith('ip:')) {
    target.ip = selectedVal.split(':')[1];
  }

  return target;
}

export function getManualTankLevel(color) {
  const key = `ewr_tank_${String(color).toLowerCase()}`;
  const saved = localStorage.getItem(key);
  if (saved !== null) {
    const parsed = parseInt(saved, 10);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return 80;
}

export function setManualTankLevel(color, level) {
  const clamped = Math.min(Math.max(Number(level) || 80, 10), 100);
  const key = `ewr_tank_${String(color).toLowerCase()}`;
  localStorage.setItem(key, String(clamped));
  return clamped;
}
