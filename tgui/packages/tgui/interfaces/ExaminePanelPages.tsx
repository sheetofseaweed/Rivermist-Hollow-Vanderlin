import { useEffect, useMemo, useState } from "react";
import { Box, Button, Image, Section, Stack } from "tgui-core/components";

import { resolveAsset } from "../assets";
import { useBackend } from "../backend";
import type { ExaminePanelData } from "./ExaminePanelData";

const CharacterPortrait = (props: { nsfw: boolean }) => {
  const { act, data } = useBackend<ExaminePanelData>();
  const {
    headshot,
    nsfw_headshot,
    has_headshot,
    has_nsfw_headshot,
    preview_image,
  } = data;
  const hasShot = props.nsfw ? has_nsfw_headshot : has_headshot;
  const shot = props.nsfw
    ? nsfw_headshot || "headshot_red.png"
    : headshot || "headshot_red.png";
  // Default to the live character preview when no headshot is set
  const [showPreview, setShowPreview] = useState(!hasShot);
  const previewActive = showPreview || !hasShot;

  // Ask the server to flatten the character the first time the preview is shown
  useEffect(() => {
    if (previewActive && !preview_image) {
      act("generate_preview");
    }
  }, [previewActive, preview_image]);

  return (
    <Stack vertical g={0.5}>
      <Stack.Item>
        <Box
          width="350px"
          height="350px"
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            margin: "0 auto",
          }}
        >
          {previewActive ? (
            preview_image ? (
              <img
                src={preview_image}
                style={{
                  // The server always sends a fixed 96x96 canvas, so a fixed
                  // render size means a constant, non-jumping sprite scale
                  width: "336px",
                  height: "336px",
                  imageRendering: "pixelated",
                }}
              />
            ) : (
              <Box color="gray" italic>
                Loading character...
              </Box>
            )
          ) : (
            <img
              src={resolveAsset(shot)}
              width="350px"
              height="350px"
              style={{ objectFit: "contain" }}
            />
          )}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" justify="center">
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-left"
                tooltip="Rotate counterclockwise"
                onClick={() => act("rotate", { clockwise: false })}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon={previewActive ? "image" : "user"}
              disabled={!hasShot}
              tooltip={
                hasShot
                  ? previewActive
                    ? "Show the headshot image"
                    : "Show the in-game character"
                  : "No headshot set"
              }
              onClick={() => setShowPreview(!previewActive)}
            >
              {previewActive ? "Headshot" : "Character Preview"}
            </Button>
          </Stack.Item>
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-right"
                tooltip="Rotate clockwise"
                onClick={() => act("rotate", { clockwise: true })}
              />
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const FlavorTextPage = (props) => {
  const { data } = useBackend<ExaminePanelData>();
  const { flavor_text, flavor_text_nsfw, ooc_notes, ooc_notes_nsfw, is_naked } =
    data;
  const [oocNotesIndex, setOocNotesIndex] = useState("SFW");
  const [flavorTextIndex, setFlavorTextIndex] = useState("SFW");

  const flavorHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text}</span>`,
    }),
    [flavor_text],
  );

  const nsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text_nsfw}</span>`,
    }),
    [flavor_text_nsfw],
  );

  const oocHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes}</span>`,
    }),
    [ooc_notes],
  );

  const oocnsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes_nsfw}</span>`,
    }),
    [ooc_notes_nsfw],
  );

  return (
    <Stack fill>
      <Stack fill vertical>
        <Stack.Item align="center">
          <CharacterPortrait nsfw={flavorTextIndex === "NSFW"} />
        </Stack.Item>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item grow width="300px">
              <Section
                scrollable
                fill
                title="OOC Notes"
                preserveWhitespace
                buttons={
                  <>
                    <Button
                      selected={oocNotesIndex === "SFW"}
                      bold={oocNotesIndex === "SFW"}
                      onClick={() => {
                        setOocNotesIndex("SFW");
                      }}
                      textAlign="center"
                      minWidth="60px"
                    >
                      SFW
                    </Button>
                    <Button
                      selected={oocNotesIndex === "NSFW"}
                      disabled={!ooc_notes_nsfw}
                      bold={oocNotesIndex === "NSFW"}
                      onClick={() => {
                        setOocNotesIndex("NSFW");
                      }}
                      textAlign="center"
                      minWidth="60px"
                    >
                      NSFW
                    </Button>
                  </>
                }
              >
                {oocNotesIndex === "SFW" && (
                  <Box
                    dangerouslySetInnerHTML={{
                      __html: ooc_notes
                        ? `<span class='Chat'>${ooc_notes}</span>`
                        : "<i>No OOC notes provided.</i>",
                    }}
                  />
                )}
                {oocNotesIndex === "NSFW" && (
                  <Box dangerouslySetInnerHTML={oocnsfwHTML} />
                )}
              </Section>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
      <Stack.Item grow>
        <Section
          scrollable
          fill
          preserveWhitespace
          title="Flavor Text"
          buttons={
            <>
              <Button
                selected={flavorTextIndex === "SFW"}
                bold={flavorTextIndex === "SFW"}
                onClick={() => setFlavorTextIndex("SFW")}
                textAlign="center"
                width="60px"
              >
                SFW
              </Button>
              <Button
                selected={flavorTextIndex === "NSFW"}
                disabled={!is_naked || !flavor_text_nsfw}
                bold={flavorTextIndex === "NSFW"}
                onClick={() => setFlavorTextIndex("NSFW")}
                textAlign="center"
                width="60px"
              >
                NSFW
              </Button>
            </>
          }
        >
          {flavorTextIndex === "SFW" && (
            <Box
              dangerouslySetInnerHTML={{
                __html: flavor_text
                  ? `<span class='Chat'>${flavor_text}</span>`
                  : "<i>No flavor text provided.</i>",
              }}
            />
          )}
          {flavorTextIndex === "NSFW" && (
            <Box dangerouslySetInnerHTML={nsfwHTML} />
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const ImageGalleryPage = () => {
  const { data } = useBackend<ExaminePanelData>();
  const { img_gallery, nsfw_img_gallery, is_naked } = data;
  const imgGallery = Array.isArray(img_gallery) ? img_gallery : [];
  const nsfwImgGallery = Array.isArray(nsfw_img_gallery)
    ? nsfw_img_gallery
    : [];

  const [galleryMode, setGalleryMode] = useState<"SFW" | "NSFW">("SFW");

  const images = galleryMode === "NSFW" ? nsfwImgGallery : imgGallery;

  return (
    <Section
      title="Image Gallery"
      fill
      scrollable
      buttons={
        <>
          <Button
            selected={galleryMode === "SFW"}
            bold={galleryMode === "SFW"}
            onClick={() => setGalleryMode("SFW")}
            textAlign="center"
            minWidth="60px"
          >
            SFW
          </Button>
          <Button
            selected={galleryMode === "NSFW"}
            disabled={!is_naked || nsfwImgGallery.length === 0}
            bold={galleryMode === "NSFW"}
            onClick={() => setGalleryMode("NSFW")}
            textAlign="center"
            minWidth="60px"
          >
            NSFW
          </Button>
        </>
      }
    >
      {images.length === 0 ? (
        <Box align="center" color="gray">
          No images available.
        </Box>
      ) : (
        <Stack fill justify="space-evenly">
          {images.map((val) => (
            <Stack.Item grow key={val}>
              <Section align="center">
                <Image
                  maxHeight="100%"
                  maxWidth="100%"
                  src={resolveAsset(val)}
                />
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};
