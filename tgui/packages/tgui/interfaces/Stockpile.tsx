//RMH EDITED - new file: TGUI parchment storefront for the TOWN STOCKPILE
//and the STOCKPILE EXTRACTOR (/obj/structure/fake_machine/stockpile and
///obj/structure/fake_machine/stockpile_withdraw). Shares the parchment theme.
import type { CSSProperties } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ---------------------------------------------------------------------------
// Types (match stockpile ui_data)
// ---------------------------------------------------------------------------
type StockItem = {
  ref: string;
  name: string;
  desc: string;
  held: number;
  price: number;
  disabled: BooleanLike;
  affordable: BooleanLike;
};

type Bounty = {
  name: string;
  payout: number;
  percent: BooleanLike;
};

type StockStat = {
  name: string;
  payout: number;
  held: number;
  oversupply: number;
  oversupplied: BooleanLike;
};

type StockpileData = {
  title: string;
  budget: number;
  compact: BooleanLike;
  can_read: BooleanLike;
  is_full: BooleanLike;
  view: string;
  items: StockItem[];
  bounties?: Bounty[];
  stocks?: StockStat[];
};

type ActFn = (action: string, params?: Record<string, unknown>) => void;

// ---------------------------------------------------------------------------
// Parchment style tokens (consume --p-* vars from the parchment theme)
// ---------------------------------------------------------------------------
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
const BUTTON_BG = 'var(--p-button-bg)';
const TITLE = 'var(--p-title)';
const TITLE_FONT = 'var(--p-title-font)';

const pageStyle: CSSProperties = {
  position: 'relative',
  minHeight: '100%',
  padding: '14px 28px 24px 28px',
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
  margin: '0 0 8px 0',
};

const rulerStyle: CSSProperties = {
  height: '1px',
  background: `linear-gradient(90deg, transparent 0%, ${INK_FAINT} 20%, ${INK_FAINT} 80%, transparent 100%)`,
  border: 'none',
  margin: '8px 0 12px 0',
};

const fieldRowStyle: CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  padding: '5px 0',
  borderBottom: `1px dashed ${PARCHMENT_SHADOW}`,
  fontSize: FONT_BODY,
};

const cardStyle: CSSProperties = {
  background: 'var(--p-card-bg)',
  border: `1px solid ${INK_FAINT}`,
  borderRadius: '2px',
  padding: '8px 12px',
  marginBottom: '10px',
  boxShadow: '1px 1px 4px var(--p-card-shadow)',
};

const subTabBarStyle: CSSProperties = {
  display: 'flex',
  gap: '4px',
  margin: '6px 0 12px 0',
};

const subTabStyle = (active: boolean): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: FONT_BODY,
  padding: '3px 14px',
  color: active ? INK : INK_FAINT,
  background: active ? 'var(--p-tab-active-bg)' : 'transparent',
  border: `1px solid ${active ? INK_SOFT : INK_FAINT}`,
  borderRadius: '2px',
  cursor: 'pointer',
  fontWeight: active ? 'bold' : 'normal',
});

const inkButtonStyle = (opts: { color?: string; disabled?: boolean } = {}): CSSProperties => {
  const col = opts.color || INK;
  return {
    fontFamily: SERIF,
    fontSize: FONT_LEAD,
    fontWeight: 'bold',
    padding: '2px 10px',
    color: col,
    background: opts.disabled ? 'transparent' : BUTTON_BG,
    border: opts.disabled ? `1px dashed ${INK_FAINT}` : `1px solid ${col}`,
    borderRadius: '2px',
    cursor: opts.disabled ? 'default' : 'pointer',
    opacity: opts.disabled ? 0.7 : 1,
    whiteSpace: 'nowrap',
  };
};

const starsIfIlliterate = (text: string, canRead: boolean) =>
  canRead ? text : text.replace(/[A-Za-z0-9]/g, '*');

const Amna = (props: { value: number }) => (
  <span>
    {props.value}
    <span style={{ color: INK_SOFT, fontSize: FONT_SMALL }}>{' a'}</span>
  </span>
);

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------
const StoredRow = (props: { budget: number; compact: boolean; act: ActFn }) => {
  const { budget, compact, act } = props;
  return (
    <div style={fieldRowStyle}>
      <div style={{ flex: '0 0 auto', color: SEAL_AMBER, marginRight: '12px' }}>Stored Amna</div>
      <div style={{ flex: 1, fontWeight: 'bold', color: INK }}>
        <Amna value={budget} />
      </div>
      <div style={{ display: 'flex', gap: '6px' }}>
        <button type="button" style={inkButtonStyle({ disabled: budget <= 0 })} disabled={budget <= 0} onClick={() => act('change')}>
          Withdraw as Coin
        </button>
        <button type="button" style={inkButtonStyle()} onClick={() => act('toggle_compact')}>
          Compact: {compact ? 'ON' : 'OFF'}
        </button>
      </div>
    </div>
  );
};

const WithdrawButton = (props: { item: StockItem; act: ActFn }) => {
  const { item, act } = props;
  if (item.disabled) {
    return <span style={{ color: INK_FAINT, fontStyle: 'italic', fontSize: FONT_LEAD }}>Withdrawing Disabled</span>;
  }
  const blocked = !item.affordable || item.held <= 0;
  return (
    <button
      type="button"
      style={inkButtonStyle({ disabled: blocked, color: blocked ? undefined : SEAL_GREEN })}
      disabled={blocked}
      onClick={() => act('withdraw', { ref: item.ref })}
      title={`Withdraw ${item.name} for ${item.price}a`}
    >
      Withdraw (<Amna value={item.price} />)
    </button>
  );
};

const ExtractView = (props: { items: StockItem[]; compact: boolean; canRead: boolean; act: ActFn }) => {
  const { items, compact, canRead, act } = props;
  if (items.length === 0) {
    return <div style={{ ...cardStyle, textAlign: 'center', color: INK_SOFT }}>The stockpile holds nothing to extract.</div>;
  }
  if (compact) {
    return (
      <div>
        {items.map((item) => (
          <div
            key={item.ref}
            style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '3px 4px', borderBottom: `1px dashed ${PARCHMENT_SHADOW}` }}
          >
            <div style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontWeight: 'bold' }}>
              {starsIfIlliterate(item.name, canRead)}
            </div>
            <div style={{ flexShrink: 0, color: INK_SOFT, fontSize: FONT_LEAD }}>
              x{item.held}
            </div>
            <div style={{ flexShrink: 0 }}>
              <WithdrawButton item={item} act={act} />
            </div>
          </div>
        ))}
      </div>
    );
  }
  return (
    <div>
      {items.map((item) => (
        <div key={item.ref} style={cardStyle}>
          <div style={{ display: 'flex', alignItems: 'baseline' }}>
            <div style={{ fontSize: FONT_TITLE, fontWeight: 'bold', color: INK, flex: 1 }}>
              {starsIfIlliterate(item.name, canRead)}
            </div>
            <div style={{ color: SEAL_AMBER, fontSize: FONT_LEAD }}>Stockpiled: {item.held}</div>
          </div>
          {!!item.desc && (
            <div style={{ color: INK_SOFT, fontStyle: 'italic', fontSize: FONT_BODY, margin: '2px 0 6px 0' }}>
              {starsIfIlliterate(item.desc, canRead)}
            </div>
          )}
          <div style={{ textAlign: 'right' }}>
            <WithdrawButton item={item} act={act} />
          </div>
        </div>
      ))}
    </div>
  );
};

const FeedView = (props: { bounties: Bounty[]; stocks: StockStat[]; canRead: boolean }) => {
  const { bounties, stocks, canRead } = props;
  return (
    <div>
      <div style={{ ...cardStyle, textAlign: 'center', color: INK_SOFT, fontStyle: 'italic' }}>
        Strike the kiosk with goods to feed the stockpile and claim your bounty.
      </div>
      {bounties.length > 0 && (
        <div style={cardStyle}>
          <div style={{ color: SEAL_AMBER, fontWeight: 'bold', marginBottom: '4px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Bounties
          </div>
          {bounties.map((b) => (
            <div key={b.name} style={{ display: 'flex', padding: '2px 0', borderBottom: `1px dashed ${PARCHMENT_SHADOW}` }}>
              <div style={{ flex: 1 }}>{starsIfIlliterate(b.name, canRead)}</div>
              <div style={{ color: SEAL_GREEN }}>
                {b.percent ? `${b.payout}%` : <Amna value={b.payout} />}
              </div>
            </div>
          ))}
        </div>
      )}
      {stocks.length > 0 && (
        <div style={cardStyle}>
          <div style={{ color: SEAL_AMBER, fontWeight: 'bold', marginBottom: '4px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Stockpile
          </div>
          {stocks.map((s) => (
            <div key={s.name} style={{ padding: '3px 0', borderBottom: `1px dashed ${PARCHMENT_SHADOW}` }}>
              <div style={{ display: 'flex' }}>
                <div style={{ flex: 1, fontWeight: 'bold' }}>{starsIfIlliterate(s.name, canRead)}</div>
                <div style={{ color: INK_SOFT }}>
                  Payout: <Amna value={s.payout} />
                </div>
              </div>
              <div style={{ fontSize: FONT_LEAD, color: INK_SOFT }}>
                Held: {s.held} · Oversupply at: {s.oversupply}
                {!!s.oversupplied && <span style={{ color: SEAL_RED, fontWeight: 'bold' }}> · !OVERSUPPLIED!</span>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------
export const Stockpile = () => {
  const { act, data } = useBackend<StockpileData>();
  const canRead = !!data.can_read;
  const isFull = !!data.is_full;
  const view = data.view || 'withdraw';

  return (
    <Window width={isFull ? 520 : 480} height={isFull ? 700 : 640} theme="parchment">
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={titleStyle}>{starsIfIlliterate(data.title, canRead)}</div>
          <StoredRow budget={data.budget} compact={!!data.compact} act={act} />
          <div style={rulerStyle} />
          {isFull && (
            <div style={subTabBarStyle}>
              <button type="button" style={subTabStyle(view === 'withdraw')} onClick={() => act('set_view', { view: 'withdraw' })}>
                Extract
              </button>
              <button type="button" style={subTabStyle(view === 'deposit')} onClick={() => act('set_view', { view: 'deposit' })}>
                Feed
              </button>
            </div>
          )}
          {view === 'deposit' && isFull ? (
            <FeedView bounties={data.bounties || []} stocks={data.stocks || []} canRead={canRead} />
          ) : (
            <ExtractView items={data.items} compact={!!data.compact} canRead={canRead} act={act} />
          )}
        </div>
      </Window.Content>
    </Window>
  );
};
