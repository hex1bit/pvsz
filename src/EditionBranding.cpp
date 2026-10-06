#include "EditionBranding.h"
#include "EditionBrandingAssets.h"
#include "Resources.h"
#include "graphics/MemoryImage.h"
#include <memory>

namespace EditionBranding
{
namespace
{
std::unique_ptr<Sexy::MemoryImage> nameImage;
std::unique_ptr<Sexy::MemoryImage> splashImage;

template <size_t N>
void PrepareTextImage(std::unique_ptr<Sexy::MemoryImage>& image,
    const uint8_t (&mask)[N], int width, int height)
{
    if (image)
        return;
    // Fixed text masks avoid platform-specific fonts and work before resources load.
    image = std::make_unique<Sexy::MemoryImage>();
    image->Create(width, height);
    auto* destination = image->GetBits();
    for (size_t i = 0; i < N; ++i)
        destination[i] = (static_cast<uint32_t>(mask[i]) << 24) | 0x00fff2c2;
    image->BitsChanged();
}
}
void DrawBadge(Sexy::Graphics* graphics, int x, int y, int width)
{
    if (!Sexy::FONT_BRIANNETOD16 || !Sexy::FONT_BRIANNETOD12)
        return;
    PrepareTextImage(nameImage, Assets::NameMask, Assets::NameWidth, Assets::NameHeight);
    Sexy::Graphics badge(*graphics);
    badge.SetColor(Sexy::Color(28, 43, 30, 225));
    badge.FillRect(x, y, width, 52);
    badge.SetColor(Sexy::Color(190, 161, 86));
    badge.DrawRect(x, y, width - 1, 51);
    badge.FillRect(x, y, 3, 52);
    if (nameImage)
    {
        badge.SetColorizeImages(false);
        badge.DrawImage(nameImage.get(), x + 13, y + 4);
    }
    else
    {
        badge.SetFont(Sexy::FONT_BRIANNETOD16);
        badge.SetColor(Sexy::Color(255, 242, 194));
        badge.DrawString("WANZI CUSTOM", x + 13, y + 22);
    }
    badge.SetFont(Sexy::FONT_BRIANNETOD12);
    badge.SetColor(Sexy::Color(208, 221, 199));
    badge.DrawString(std::string("v") + Version + "  /  " + BuildId, x + 13, y + 41);
}

void ReleaseImages()
{
    nameImage.reset();
    splashImage.reset();
}

void DrawSplash(Sexy::Graphics* graphics, int width, int height, int alpha)
{
    PrepareTextImage(splashImage, Assets::SplashMask, Assets::SplashWidth, Assets::SplashHeight);
    Sexy::Graphics splash(*graphics);
    const int centerX = width / 2;
    const int centerY = height / 2;
    splash.SetColor(Sexy::Color(25, 43, 30, alpha));
    splash.FillRect(centerX - 220, centerY - 86, 440, 172);
    splash.SetColor(Sexy::Color(190, 161, 86, alpha));
    splash.DrawRect(centerX - 220, centerY - 86, 439, 171);
    splash.FillRect(centerX - 42, centerY - 61, 84, 3);
    if (splashImage)
    {
        splash.SetColorizeImages(true);
        splash.SetColor(Sexy::Color(255, 255, 255, alpha));
        const int textWidth = splashImage->mWidth * 3;
        splash.DrawImage(splashImage.get(), centerX - textWidth / 2, centerY - 27, textWidth, 72);
    }
    splash.SetColor(Sexy::Color(190, 161, 86, alpha));
    splash.FillRect(centerX - 90, centerY + 61, 180, 1);
}
}
