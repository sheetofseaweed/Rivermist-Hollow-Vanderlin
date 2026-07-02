//RMH EDITED - new file: TGUI parchment panel for the SKY HANDLER beacon
///obj/item/fake_machine/merchant. Read-only: live timer to the next balloon,
//the tax breakdown taken from each sale, and a rolling sale history.
import type { CSSProperties } from 'react';
import { useEffect, useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SaleEntry = {
  name: string;
  value: number;
};

type NavigatorData = {
  motto: string;
  can_read: BooleanLike;
  next_airlift_seconds: number;
  guild_tax_percent: number;
  lord_tax_percent: number;
  total_tax_percent: number;
  viewer_exempt: BooleanLike;
  history: SaleEntry[];
};

// Parchment style tokens (consume --p-* vars from the parchment theme)
const SERIF = '"Lora", Georgia, serif';
const FONT_SMALL = 'var(--p-font-small)';
const FONT_BODY = 'var(--p-font-body)';
const FONT_LEAD = 'var(--p-font-lead)';
const FONT_TITLE = 'var(--p-font-title)';
const INK = 'var(--p-ink)';
const INK_SOFT = 'var(--p-ink-soft)';
const INK_FAINT = 'var(--p-ink-faint)';
const PARCHMENT_SHADOW = 'var(--p-bg-shadow)';
const SEAL_RED = 'var(--p-seal-red)';
const SEAL_GREEN = 'var(--p-seal-green)';
const SEAL_AMBER = 'var(--p-seal-amber)';
const TITLE = 'var(--p-title)';
const TITLE_FONT = 'var(--p-title-font)';

const pageStyle: CSSProperties = {
  position: 'relative',
  minHeight: '100%',
  padding: '16px 28px 24px 28px',
  fontFamily: SERIF,
  color: INK,
  fontSize: FONT_BODY,
  lineHeight: 1.5,
};

const titleStyle: CSSProperties = {
  textAlign: 'center',
  fontSize: '20px',
  fontWeight: 'bold',
  fontFamily: TITLE_FONT,
  color: TITLE,
  margin: '0 0 4px 0',
};

const rulerStyle: CSSProperties = {
  height: '1px',
  background: `linear-gradient(90deg, transparent 0%, ${INK_FAINT} 20%, ${INK_FAINT} 80%, transparent 100%)`,
  border: 'none',
  margin: '10px 0 14px 0',
};

const cardStyle: CSSProperties = {
  background: 'var(--p-card-bg)',
  border: `1px solid ${INK_FAINT}`,
  borderRadius: '2px',
  padding: '10px 14px',
  marginBottom: '12px',
  boxShadow: '1px 1px 4px var(--p-card-shadow)',
};

const labelStyle: CSSProperties = {
  textAlign: 'center',
  color: SEAL_AMBER,
  fontWeight: 'bold',
  textTransform: 'uppercase',
  letterSpacing: '0.5px',
  fontSize: FONT_LEAD,
  marginBottom: '4px',
};

const taxRowStyle: CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  padding: '3px 0',
  borderBottom: `1px dashed ${PARCHMENT_SHADOW}`,
  fontSize: FONT_BODY,
};

const starsIfIlliterate = (text: string, canRead: boolean) =>
  canRead ? text : text.replace(/[A-Za-z0-9]/g, '*');

const formatClock = (totalSeconds: number) => {
  const s = Math.max(0, Math.floor(totalSeconds));
  const mm = Math.floor(s / 60);
  const ss = s % 60;
  return `${String(mm).padStart(2, '0')}:${String(ss).padStart(2, '0')}`;
};

// Live local countdown that re-syncs whenever the server pushes a new value.
const useCountdown = (serverSeconds: number) => {
  const [seconds, setSeconds] = useState(serverSeconds);
  useEffect(() => {
    setSeconds(serverSeconds);
  }, [serverSeconds]);
  useEffect(() => {
    const id = setInterval(() => setSeconds((s) => (s > 0 ? s - 1 : 0)), 1000);
    return () => clearInterval(id);
  }, []);
  return seconds;
};

const Amna = (props: { value: number }) => (
  <span>
    {props.value}
    <span style={{ color: INK_SOFT, fontSize: FONT_SMALL }}>{' a'}</span>
  </span>
);

export const Navigator = () => {
  const { data } = useBackend<NavigatorData>();
  const canRead = !!data.can_read;
  const remaining = useCountdown(data.next_airlift_seconds);
  const exempt = !!data.viewer_exempt;
  const effectiveTotal = exempt ? data.lord_tax_percent : data.total_tax_percent;

  return (
    <Window width={460} height={600} theme="parchment">
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={titleStyle}>{starsIfIlliterate(data.motto, canRead)}</div>
          <div style={rulerStyle} />

          {/* Next balloon timer */}
          <div style={cardStyle}>
            <div style={labelStyle}>Next Balloon</div>
            <div style={{ textAlign: 'center', fontSize: '28px', fontWeight: 'bold', color: INK, fontFamily: TITLE_FONT }}>
              {formatClock(remaining)}
            </div>
            <div style={{ textAlign: 'center', color: INK_SOFT, fontStyle: 'italic', fontSize: FONT_LEAD }}>
              Drop goods on the surrounding tiles. The balloon lifts them away and leaves your coin.
            </div>
          </div>

          {/* Tax breakdown. Guild members are spared the guild levy. */}
          <div style={cardStyle}>
            <div style={labelStyle}>Toll on Every Sale</div>
            <div style={taxRowStyle}>
              <span>Merchant Guild Levy</span>
              {exempt ? (
                <span>
                  <span style={{ color: INK_FAINT, textDecoration: 'line-through', marginRight: '6px' }}>
                    {data.guild_tax_percent}%
                  </span>
                  <span style={{ color: SEAL_GREEN, fontWeight: 'bold' }}>WAIVED</span>
                </span>
              ) : (
                <span style={{ color: SEAL_AMBER, fontWeight: 'bold' }}>{data.guild_tax_percent}%</span>
              )}
            </div>
            <div style={taxRowStyle}>
              <span>Lord&apos;s Export Tax</span>
              <span style={{ color: SEAL_AMBER, fontWeight: 'bold' }}>{data.lord_tax_percent}%</span>
            </div>
            <div style={{ ...taxRowStyle, borderBottom: 'none', marginTop: '2px' }}>
              <span style={{ fontWeight: 'bold' }}>Total Withheld</span>
              <span style={{ color: SEAL_RED, fontWeight: 'bold' }}>{effectiveTotal}%</span>
            </div>
            <div style={{ textAlign: 'center', color: SEAL_GREEN, fontSize: FONT_LEAD, marginTop: '4px' }}>
              You keep {Math.max(0, 100 - effectiveTotal)}% of the sale.
            </div>
            {exempt && (
              <div style={{ textAlign: 'center', color: SEAL_GREEN, fontSize: FONT_LEAD, fontStyle: 'italic', marginTop: '2px' }}>
                As a guild member, the guild levy is waived for you.
              </div>
            )}
          </div>

          {/* Sale history */}
          <div style={cardStyle}>
            <div style={labelStyle}>Recent Shipments</div>
            {data.history.length === 0 ? (
              <div style={{ textAlign: 'center', color: INK_SOFT, fontStyle: 'italic' }}>
                Nothing has been shipped yet.
              </div>
            ) : (
              <div>
                {data.history.map((entry, i) => (
                  <div
                    key={i}
                    style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0', borderBottom: `1px dashed ${PARCHMENT_SHADOW}`, fontSize: FONT_LEAD }}
                  >
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginRight: '8px' }}>
                      {starsIfIlliterate(entry.name, canRead)}
                    </span>
                    <span style={{ color: INK_SOFT, flexShrink: 0 }}>
                      <Amna value={entry.value} />
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
