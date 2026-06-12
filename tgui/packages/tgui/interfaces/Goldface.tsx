//RMH EDITED - new file: TGUI storefront for the GOLDFACE / SILVERFACE vendor.
//Visual ported from Azure Peak's Goldface "VendingPanel", wired to Vanderlin data.
import type { CSSProperties } from 'react';
import type { ReactNode } from 'react';
import { useEffect, useState } from 'react';
import { Input } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ---------------------------------------------------------------------------
// Types (match merchantvend/ui_data)
// ---------------------------------------------------------------------------
type VendingPack = {
  ref: string;
  name: string;
  category: string;
  qty: number;
  price: number;
  price_base: number;
  price_tariff: number;
};

type VendingData = {
  motto: string;
  budget: number;
  can_read: BooleanLike;
  locked: BooleanLike;
  is_public: BooleanLike;
  is_proprietor: BooleanLike;
  is_agent: BooleanLike;
  is_command_center: BooleanLike;
  tariff_rate_pct: number;
  tariff_paid: number;
  tariff_evaded: number;
  dodging: BooleanLike;
  public_margin_pct?: number;
  public_margin_label?: string;
  categories: string[];
  current_category: string | null;
  search: string;
  search_mode: BooleanLike;
  result_cap: number;
  total_matches: number;
  packs: VendingPack[];
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
  padding: '18px 28px 28px 28px',
  fontFamily: SERIF,
  color: INK,
  fontSize: FONT_BODY,
  lineHeight: 1.5,
};

const titleStyle: CSSProperties = {
  textAlign: 'center',
  fontSize: '22px',
  fontWeight: 'bold',
  fontFamily: TITLE_FONT,
  color: TITLE,
  margin: '0 0 4px 0',
};

const subtitleStyle: CSSProperties = {
  textAlign: 'center',
  color: INK_SOFT,
  fontStyle: 'italic',
  fontSize: FONT_BODY,
  marginBottom: '10px',
};

const rulerStyle: CSSProperties = {
  height: '1px',
  background: `linear-gradient(90deg, transparent 0%, ${INK_FAINT} 20%, ${INK_FAINT} 80%, transparent 100%)`,
  border: 'none',
  margin: '8px 0 14px 0',
};

const subTabBarStyle: CSSProperties = {
  display: 'flex',
  flexWrap: 'wrap',
  gap: '4px',
  justifyContent: 'flex-start',
  margin: '6px 0',
};

const subTabStyle = (active: boolean): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: FONT_BODY,
  padding: '3px 10px',
  color: active ? INK : INK_FAINT,
  background: active ? 'var(--p-tab-active-bg)' : 'transparent',
  border: `1px solid ${active ? INK_SOFT : INK_FAINT}`,
  borderRadius: '2px',
  cursor: 'pointer',
  fontWeight: active ? 'bold' : 'normal',
  whiteSpace: 'nowrap',
});

const cardStyle: CSSProperties = {
  background: 'var(--p-card-bg)',
  border: `1px solid ${INK_FAINT}`,
  borderRadius: '2px',
  padding: '8px 12px',
  marginBottom: '10px',
  boxShadow: '1px 1px 4px var(--p-card-shadow)',
};

const fieldRowStyle: CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  padding: '5px 0',
  borderBottom: `1px dashed ${PARCHMENT_SHADOW}`,
  fontSize: FONT_BODY,
};

const denseRowStyle: CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '6px',
  padding: '4px 6px',
  borderBottom: `1px dashed ${PARCHMENT_SHADOW}`,
  fontFamily: SERIF,
  lineHeight: 1.3,
};

const ellipsisCellStyle: CSSProperties = {
  flex: 1,
  minWidth: 0,
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
};

const inkButtonStyle = (opts: { color?: string; disabled?: boolean } = {}): CSSProperties => {
  const col = opts.color || INK;
  return {
    fontFamily: SERIF,
    fontSize: FONT_BODY,
    fontWeight: 'bold',
    padding: '2px 10px',
    color: col,
    background: opts.disabled ? 'transparent' : BUTTON_BG,
    border: opts.disabled ? `1px dashed ${INK_FAINT}` : `1px solid ${col}`,
    borderRadius: '2px',
    cursor: opts.disabled ? 'default' : 'pointer',
    opacity: opts.disabled ? 0.7 : 1,
    transition: 'background-color 80ms linear',
  };
};

const compactButtonStyle = (opts: { color?: string; disabled?: boolean } = {}): CSSProperties => ({
  ...inkButtonStyle(opts),
  padding: '1px 7px',
  fontSize: FONT_LEAD,
});

const starsIfIlliterate = (text: string, canRead: boolean) =>
  canRead ? text : text.replace(/[A-Za-z0-9]/g, '*');

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------
const PriceTag = (props: {
  price: number;
  tariff?: number;
  cantAfford?: boolean;
  title?: string;
}) => {
  const { price, tariff, cantAfford, title } = props;
  const hasTariff = !!tariff && tariff > 0;
  return (
    <div
      style={{
        fontSize: FONT_LEAD,
        color: cantAfford ? INK_FAINT : INK,
        flexShrink: 0,
        whiteSpace: 'nowrap',
      }}
      title={title}
    >
      <span>{price}</span>
      {hasTariff && (
        <span style={{ color: SEAL_AMBER, fontSize: FONT_BODY, marginLeft: '2px' }}>
          +{tariff}
        </span>
      )}
      <span style={{ color: INK_SOFT, fontSize: FONT_SMALL }}>{' a'}</span>
    </div>
  );
};

const AmnaRow = (props: { budget: number; canRead: boolean; isProprietor: boolean; isPublic: boolean; act: ActFn }) => {
  const { budget, canRead, isProprietor, isPublic, act } = props;
  return (
    <div style={fieldRowStyle}>
      <div style={{ flex: '0 0 auto', fontFamily: SERIF, color: SEAL_AMBER, marginRight: '12px' }}>
        Amna Loaded
      </div>
      <div style={{ flex: 1, fontWeight: 'bold', color: INK }}>{budget}a</div>
      <div style={{ display: 'flex', gap: '6px' }}>
        <button
          type="button"
          style={inkButtonStyle({ disabled: budget <= 0 })}
          disabled={budget <= 0}
          onClick={() => act('change')}
        >
          Withdraw as Coin
        </button>
        {isProprietor && !isPublic && (
          <button type="button" style={inkButtonStyle()} onClick={() => act('secrets')}>
            {starsIfIlliterate('Secrets', canRead)}
          </button>
        )}
      </div>
    </div>
  );
};

const TariffHeader = (props: {
  motto: string;
  canRead: boolean;
  tariffRatePct: number;
  tariffPaid: number;
  tariffEvaded: number;
  isProprietor: boolean;
  dodging: boolean;
  publicMarginPct?: number;
  publicMarginLabel?: string;
}) => {
  const { motto, canRead, tariffRatePct, tariffPaid, tariffEvaded, isProprietor, dodging, publicMarginPct, publicMarginLabel } = props;
  return (
    <>
      <div style={titleStyle}>{starsIfIlliterate(motto, canRead)}</div>
      <div style={subtitleStyle}>
        Lord&apos;s Import Toll: <b>{tariffRatePct}%</b>
        {isProprietor && dodging && (
          <span style={{ color: SEAL_RED, marginLeft: '8px' }}>
            <b>(TAX DODGING)</b>
          </span>
        )}
        {publicMarginPct !== undefined && (
          <span style={{ color: SEAL_AMBER, marginLeft: '8px' }}>
            · {publicMarginLabel || 'Public Margin'}: <b>+{publicMarginPct}%</b>
          </span>
        )}
      </div>
      {isProprietor && (
        <div style={{ textAlign: 'center', fontFamily: SERIF, fontSize: FONT_BODY, marginBottom: '4px' }}>
          <span style={{ color: SEAL_GREEN }}>Paid: {tariffPaid}a</span>
          <span style={{ color: INK_FAINT, margin: '0 6px' }}>·</span>
          <span style={{ color: SEAL_RED }}>Evaded: {tariffEvaded}a</span>
        </div>
      )}
      <div style={rulerStyle} />
    </>
  );
};

const SearchBar = (props: { serverSearch: string; act: ActFn }) => {
  const { serverSearch, act } = props;
  const [draft, setDraft] = useState(serverSearch);

  useEffect(() => {
    if (draft === serverSearch) return;
    const id = setTimeout(() => act('set_search', { search: draft }), 250);
    return () => clearTimeout(id);
  }, [draft, serverSearch, act]);

  useEffect(() => {
    setDraft(serverSearch);
  }, [serverSearch]);

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', margin: '8px 0' }}>
      <span style={{ fontFamily: SERIF, fontSize: FONT_BODY, color: INK_SOFT }}>Search all goods:</span>
      <Input
        value={draft}
        onChange={(value: string) => setDraft(value)}
        placeholder="Type to search across categories..."
        width="280px"
      />
      {!!draft && (
        <button
          type="button"
          style={inkButtonStyle()}
          onClick={() => {
            setDraft('');
            act('clear_search');
          }}
        >
          Clear
        </button>
      )}
    </div>
  );
};

const PackRow = (props: { pack: VendingPack; budget: number; canRead: boolean; showCategory: boolean; act: ActFn }) => {
  const { pack, budget, canRead, showCategory, act } = props;
  const cantAfford = budget < pack.price;
  const hasTariff = pack.price_tariff > 0;
  const priceTitle = hasTariff
    ? `${pack.price_base}a + ${pack.price_tariff}a tariff = ${pack.price}a`
    : `${pack.price}a`;
  return (
    <div style={denseRowStyle}>
      <div
        style={{ ...ellipsisCellStyle, fontSize: FONT_TITLE, color: INK }}
        title={showCategory ? `${pack.name} - ${pack.category}` : pack.name}
      >
        {pack.qty > 1 && (
          <span style={{ color: INK_SOFT, marginRight: '4px', fontSize: FONT_LEAD }}>x{pack.qty}</span>
        )}
        {starsIfIlliterate(pack.name, canRead)}
      </div>
      <PriceTag price={pack.price} tariff={pack.price_tariff} cantAfford={cantAfford} title={priceTitle} />
      <div style={{ flexShrink: 0 }}>
        <button
          type="button"
          style={compactButtonStyle({ disabled: cantAfford })}
          disabled={cantAfford}
          onClick={() => act('buy', { ref: pack.ref })}
          title={`Buy ${pack.name} for ${pack.price}a`}
        >
          Buy
        </button>
      </div>
    </div>
  );
};

const HintCard = (props: { children: ReactNode }) => (
  <div style={{ ...cardStyle, textAlign: 'center', color: INK_SOFT }}>{props.children}</div>
);

// Legend row. Placed as the first item in the multi-column flow so it sits at
// the top of the FIRST column only, on its own level above the goods grid.
const PackHeader = () => (
  <div
    style={{
      ...denseRowStyle,
      borderBottom: `1px solid ${INK_FAINT}`,
      color: SEAL_AMBER,
      fontWeight: 'bold',
      fontSize: FONT_BODY,
      textTransform: 'uppercase',
      letterSpacing: '0.5px',
    }}
  >
    <div style={ellipsisCellStyle}>Goods</div>
    <div style={{ flexShrink: 0 }}>Price,</div>
    <div style={{ flexShrink: 0 }}>Amnas</div>
  </div>
);

const PacksGrid = (props: {
  packs: VendingPack[];
  budget: number;
  canRead: boolean;
  inSearchMode: boolean;
  serverSearch: string;
  hasCategory: boolean;
  resultCap: number;
  totalMatches: number;
  act: ActFn;
}) => {
  const { packs, budget, canRead, inSearchMode, serverSearch, hasCategory, resultCap, totalMatches, act } = props;

  if (!hasCategory && !inSearchMode) {
    return <HintCard>Select a category above, or type in the search to find goods.</HintCard>;
  }
  if (packs.length === 0) {
    return (
      <HintCard>
        {inSearchMode ? `No goods match "${serverSearch}".` : 'No goods stocked in this category.'}
      </HintCard>
    );
  }

  const overflowed = inSearchMode && totalMatches > resultCap;
  return (
    <>
      {/* Legend sits on its own level, one column wide, above the goods. */}
      <div style={{ width: 'calc((100% - 24px) / 3)' }}>
        <PackHeader />
      </div>
      <div style={{ columnCount: 3, columnGap: '12px' }}>
        {packs.map((p) => (
          <div key={p.ref} style={{ breakInside: 'avoid' }}>
            <PackRow pack={p} budget={budget} canRead={canRead} showCategory={inSearchMode} act={act} />
          </div>
        ))}
      </div>
      {overflowed && (
        <div style={{ marginTop: '8px', textAlign: 'center', fontFamily: SERIF, fontSize: FONT_BODY, color: INK_SOFT }}>
          Showing {resultCap} of {totalMatches} matches. Refine your search to narrow the list.
        </div>
      )}
    </>
  );
};

const LockedView = (props: { motto: string; canRead: boolean }) => (
  <div style={pageStyle}>
    <div style={titleStyle}>{starsIfIlliterate(props.motto, props.canRead)}</div>
    <div style={rulerStyle} />
    <div style={{ ...cardStyle, textAlign: 'center', fontStyle: 'italic', color: INK_SOFT }}>
      It is locked. Of course.
    </div>
  </div>
);

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------
export const Goldface = () => {
  const { act, data } = useBackend<VendingData>();
  const canRead = !!data.can_read;
  const isPublic = !!data.is_public;
  const locked = !!data.locked;
  const isProprietor = !!data.is_proprietor;
  const inSearchMode = !!data.search_mode;

  return (
    <Window width={880} height={800} theme="parchment">
      <Window.Content scrollable>
        <div style={{ padding: '6px 28px 0 28px' }}>
          <AmnaRow
            budget={data.budget}
            canRead={canRead}
            isProprietor={isProprietor}
            isPublic={isPublic}
            act={act}
          />
        </div>
        {locked && !isPublic ? (
          <LockedView motto={data.motto} canRead={canRead} />
        ) : (
          <div style={pageStyle}>
            <TariffHeader
              motto={data.motto}
              canRead={canRead}
              tariffRatePct={data.tariff_rate_pct}
              tariffPaid={data.tariff_paid}
              tariffEvaded={data.tariff_evaded}
              isProprietor={isProprietor}
              dodging={!!data.dodging}
              publicMarginPct={data.public_margin_pct}
              publicMarginLabel={data.public_margin_label}
            />
            <div style={subTabBarStyle}>
              {data.categories.map((cat) => {
                const isActive = data.current_category === cat;
                return (
                  <button
                    type="button"
                    key={cat}
                    style={subTabStyle(isActive)}
                    onClick={() => act('changecat', { category: isActive ? '' : cat })}
                    title={isActive ? 'Click again to clear the category filter' : `Browse ${cat}`}
                  >
                    {cat}
                  </button>
                );
              })}
              {!!data.current_category && (
                <button
                  type="button"
                  style={subTabStyle(false)}
                  onClick={() => act('changecat', { category: '' })}
                  title="Clear category filter"
                >
                  × Clear
                </button>
              )}
            </div>
            <SearchBar serverSearch={data.search} act={act} />
            <PacksGrid
              packs={data.packs}
              budget={data.budget}
              canRead={canRead}
              inSearchMode={inSearchMode}
              serverSearch={data.search}
              hasCategory={!!data.current_category}
              resultCap={data.result_cap}
              totalMatches={data.total_matches}
              act={act}
            />
          </div>
        )}
      </Window.Content>
    </Window>
  );
};
