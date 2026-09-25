import type { CSSProperties } from 'react';
import { useState } from 'react';
import { RestrictedInput } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SkyLevyData = {
  current_levy: number;
  lord_tax: number;
  min_seller_share: number;
  max_levy: number;
};

const SERIF = '"Lora", Georgia, serif';
const INK = 'var(--p-ink)';
const INK_SOFT = 'var(--p-ink-soft)';
const INK_FAINT = 'var(--p-ink-faint)';
const TITLE = 'var(--p-title)';

const pageStyle: CSSProperties = {
  padding: '14px 20px',
  fontFamily: SERIF,
  color: INK,
  fontSize: 'var(--p-font-body)',
  lineHeight: 1.5,
};

const rowStyle: CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  gap: '8px',
  margin: '6px 0',
};

const buttonStyle = (disabled = false): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: 'var(--p-font-body)',
  padding: '3px 16px',
  color: disabled ? INK_FAINT : INK,
  background: 'var(--p-button-bg, transparent)',
  border: `1px solid ${disabled ? INK_FAINT : INK_SOFT}`,
  borderRadius: '2px',
  cursor: disabled ? 'default' : 'pointer',
});

export const SkyLevy = () => {
  const { act, data } = useBackend<SkyLevyData>();
  const [value, setValue] = useState(data.current_levy);
  const [valid, setValid] = useState(true);
  const inRange = valid && value >= 0 && value <= data.max_levy;

  return (
    <Window width={320} height={230} theme="parchment">
      <Window.Content>
        <div style={pageStyle}>
          <div style={rowStyle}>
            <span>Current levy</span>
            <b style={{ color: TITLE }}>{data.current_levy}%</b>
          </div>
          <div style={rowStyle}>
            <span>Change value</span>
            <span>
              <RestrictedInput
                width="60px"
                value={value}
                minValue={0}
                maxValue={data.max_levy}
                onChange={(val: number) => setValue(val)}
                onValidationChange={(isValid: boolean) => setValid(isValid)}
                onEnter={(val: number) => act('set', { value: val })}
              />{' '}
              %
            </span>
          </div>
          <div style={{ color: INK_SOFT, fontStyle: 'italic', fontSize: 'var(--p-font-small)' }}>
            Allowed: 0–{data.max_levy}%. Lord&apos;s tax is {data.lord_tax}%, sellers always keep at least{' '}
            {data.min_seller_share}%.
          </div>
          <div style={{ ...rowStyle, justifyContent: 'center', gap: '12px', marginTop: '14px' }}>
            <button
              type="button"
              style={buttonStyle(!inRange)}
              disabled={!inRange}
              onClick={() => act('set', { value })}
            >
              Set
            </button>
            <button type="button" style={buttonStyle()} onClick={() => act('cancel')}>
              Cancel
            </button>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
