import type { CSSProperties } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  quest_title: string;
  description: string;
  payment: string;
  poster_name: string;
  completed: boolean;
  signed_by_leader: boolean;
  signed_by_name: string;
};

// Styled after Azure Peak's QuestScroll ("enchanted contract scroll") -
// tgui/packages/tgui/interfaces/QuestScroll/shared.ts's `parchment` /
// `bountyHeader` / `divider` / `completionStamp` constants. That widget
// leans on `theme="parchment"` CSS variables (--p-ink, --p-card-bg, etc.)
// rather than its own stylesheet - RMH already has that exact theme
// contract ported (tgui/packages/tgui/styles/themes/parchment.scss, used by
// Goldface/Navigator/Stockpile), so this reuses it as-is instead of adding
// yet another easy-to-forget main.scss line.

const parchment: CSSProperties = {
  position: 'relative',
  color: 'var(--p-ink)',
  fontFamily: "'Lora', Georgia, serif",
  padding: '24px 28px',
  minHeight: '100%',
  boxSizing: 'border-box',
  lineHeight: '1.55em',
};

const title: CSSProperties = {
  fontFamily: 'var(--p-title-font)',
  color: 'var(--p-title)',
  fontSize: '1.5em',
  fontWeight: 'bold',
  textAlign: 'center',
  marginBottom: '10px',
  paddingBottom: '10px',
  borderBottom: '1px dashed var(--p-ink-faint)',
};

const objective: CSSProperties = {
  fontStyle: 'italic',
  textAlign: 'center',
  lineHeight: '1.5',
  margin: '14px 0',
};

// A full blank line's worth of breathing room before the info box, so it
// doesn't sit crammed right under the description text.
const infoBox: CSSProperties = {
  background: 'var(--p-card-bg)',
  border: '1px solid var(--p-ink-faint)',
  borderRadius: '2px',
  padding: '10px 14px',
  marginTop: '34px',
};

const row: CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  gap: '10px',
  margin: '4px 0',
};

const label: CSSProperties = {
  fontStyle: 'italic',
  color: 'var(--p-ink-soft)',
};

const value: CSSProperties = {
  fontWeight: 'bold',
  textAlign: 'right',
};

// Three fixed slots near the middle of the page, each with its own tilt -
// picked deterministically per-quest so the stamp doesn't jump around every
// time the scroll is reopened. Angles stay well short of upside down.
const STAMP_SLOTS: { top: string; left: string; rotate: number }[] = [
  { top: '38%', left: '32%', rotate: -16 },
  { top: '46%', left: '60%', rotate: 12 },
  { top: '55%', left: '40%', rotate: -7 },
];

const hashText = (s: string) => {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
};

const stampBase: CSSProperties = {
  position: 'absolute',
  textAlign: 'center',
  fontWeight: 'bold',
  fontSize: '1.9em',
  letterSpacing: '2px',
  textTransform: 'uppercase',
  padding: '6px 18px',
  border: '3px double currentColor',
  borderRadius: '4px',
  opacity: 0.82,
  pointerEvents: 'none',
  whiteSpace: 'nowrap',
  background: 'rgba(255, 252, 240, 0.35)',
};

const stampSignature: CSSProperties = {
  display: 'block',
  fontSize: '0.4em',
  fontWeight: 'normal',
  fontStyle: 'italic',
  letterSpacing: 'normal',
  textTransform: 'none',
  marginTop: '2px',
};

export const QuestScroll = () => {
  const { data } = useBackend<Data>();

  const slot =
    STAMP_SLOTS[hashText(data.quest_title + data.poster_name) % STAMP_SLOTS.length];
  const stampColor = data.signed_by_leader ? 'var(--p-seal-green)' : 'var(--p-ink)';
  const stampStyle: CSSProperties = {
    ...stampBase,
    top: slot.top,
    left: slot.left,
    color: stampColor,
    transform: `translate(-50%, -50%) rotate(${slot.rotate}deg)`,
  };

  return (
    <Window
      title={data.quest_title || 'Quest Parchment'}
      theme="parchment"
      width={420}
      height={480}
    >
      <Window.Content scrollable>
        <div style={parchment}>
          <div style={title}>{data.quest_title}</div>
          <div
            style={objective}
            dangerouslySetInnerHTML={{ __html: data.description }}
          />
          <div style={infoBox}>
            <div style={row}>
              <span style={label}>Payment:</span>
              <span style={value}>{data.payment}</span>
            </div>
            <div style={row}>
              <span style={label}>Posted by:</span>
              <span style={value}>{data.poster_name}</span>
            </div>
          </div>
          {!!data.completed && (
            <div style={stampStyle}>
              Complete
              <span style={stampSignature}>{data.signed_by_name}</span>
            </div>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};
