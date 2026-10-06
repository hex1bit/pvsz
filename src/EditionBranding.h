#pragma once

// Custom edition identity. Keep upstream and original game attribution intact.
#include <string>
#include "graphics/Graphics.h"

namespace EditionBranding
{
inline constexpr char Name[] = "丸子定制版本";
inline constexpr char SplashName[] = "WanZi Family";
inline constexpr char Version[] = "0.1.0";
inline constexpr char BuildId[] = "WZ-GOTY-001";

inline std::string WindowTitle()
{
    return std::string("Plants vs. Zombies | ") + Name + " v" + Version;
}

void DrawBadge(Sexy::Graphics* graphics, int x, int y, int width);
void DrawSplash(Sexy::Graphics* graphics, int width, int height, int alpha);
void ReleaseImages();
}
