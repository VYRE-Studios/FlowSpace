import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../database/prisma.service';
import axios from 'axios';

interface GitHubRelease {
  tag_name: string;
  name: string;
  body: string;
  draft: boolean;
  prerelease: boolean;
  created_at: string;
  published_at: string;
  assets: Array<{
    name: string;
    browser_download_url: string;
    size: number;
  }>;
}

interface UpdateCheckResponse {
  updateAvailable: boolean;
  currentVersion: string;
  latestVersion?: string;
  downloadUrl?: string;
  releaseNotes?: string;
  platform: string;
}

@Injectable()
export class UpdatesService {
  private readonly logger = new Logger(UpdatesService.name);
  private readonly githubOwner: string;
  private readonly githubRepo: string;
  private readonly githubToken?: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    // Configure GitHub repository (defaults to your repo structure)
    this.githubOwner = this.config.get<string>('GITHUB_OWNER') || 'jwhit0';
    this.githubRepo = this.config.get<string>('GITHUB_REPO') || 'Flo';
    this.githubToken = this.config.get<string>('GITHUB_TOKEN');
  }

  /**
   * Check if updates are available for the client
   */
  async checkForUpdates(
    version: string,
    build: string,
    platform: string,
  ): Promise<UpdateCheckResponse> {
    this.logger.log(
      `[Update Check] Client running v${version} (${build}) on ${platform}`,
    );

    try {
      // Fetch latest release from GitHub
      const latestRelease = await this.fetchLatestGitHubRelease();

      if (!latestRelease) {
        this.logger.warn('No releases found on GitHub');
        return {
          updateAvailable: false,
          currentVersion: version,
          platform,
        };
      }

      // Parse version from tag (assumes format like v1.0.0 or 1.0.0)
      const latestVersion = latestRelease.tag_name.replace(/^v/, '');

      // Compare versions
      const updateAvailable = this.compareVersions(latestVersion, version) > 0;

      if (!updateAvailable) {
        this.logger.log(`Client is up to date (v${version})`);
        return {
          updateAvailable: false,
          currentVersion: version,
          latestVersion,
          platform,
        };
      }

      // Find appropriate download URL for platform
      const downloadUrl = this.getDownloadUrlForPlatform(
        latestRelease.assets,
        platform,
      );

      this.logger.log(
        `Update available: v${version} -> v${latestVersion}`,
      );

      // Store/update in database for caching
      await this.upsertUpdateRecord(
        latestVersion,
        latestRelease.tag_name,
        platform,
        downloadUrl,
        latestRelease.body,
      );

      return {
        updateAvailable: true,
        currentVersion: version,
        latestVersion,
        downloadUrl: downloadUrl || undefined,
        releaseNotes: latestRelease.body || undefined,
        platform,
      };
    } catch (error: any) {
      this.logger.error(`Error checking for updates: ${error.message}`);
      // Fallback to database if GitHub API fails
      return this.checkFromDatabase(version, platform);
    }
  }

  /**
   * Get the latest version info without comparing
   */
  async getLatestVersion(platform: string) {
    try {
      const latestRelease = await this.fetchLatestGitHubRelease();

      if (!latestRelease) {
        return this.getLatestFromDatabase(platform);
      }

      const version = latestRelease.tag_name.replace(/^v/, '');
      const downloadUrl = this.getDownloadUrlForPlatform(
        latestRelease.assets,
        platform,
      );

      return {
        version,
        build: latestRelease.tag_name,
        platform,
        downloadUrl,
        releaseNotes: latestRelease.body,
        publishedAt: latestRelease.published_at,
      };
    } catch (error: any) {
      this.logger.error(`Error fetching latest version: ${error.message}`);
      return this.getLatestFromDatabase(platform);
    }
  }

  /**
   * Fetch latest release from GitHub API
   */
  private async fetchLatestGitHubRelease(): Promise<GitHubRelease | null> {
    const url = `https://api.github.com/repos/${this.githubOwner}/${this.githubRepo}/releases/latest`;

    const headers: Record<string, string> = {
      Accept: 'application/vnd.github.v3+json',
      'User-Agent': 'FlowSpace-Update-Checker',
    };

    if (this.githubToken) {
      headers.Authorization = `Bearer ${this.githubToken}`;
    }

    try {
      const response = await axios.get<GitHubRelease>(url, {
        headers,
        timeout: 10000,
      });

      // Filter out drafts and prereleases
      if (response.data.draft || response.data.prerelease) {
        this.logger.debug('Latest release is draft or prerelease, skipping');
        return null;
      }

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 404) {
        this.logger.warn('No releases found on GitHub');
      } else {
        this.logger.error(
          `GitHub API error: ${error.response?.status || error.message}`,
        );
      }
      return null;
    }
  }

  /**
   * Compare two semantic versions
   * Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
   */
  private compareVersions(v1: string, v2: string): number {
    const parts1 = v1.split('.').map((n) => parseInt(n, 10) || 0);
    const parts2 = v2.split('.').map((n) => parseInt(n, 10) || 0);

    for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
      const part1 = parts1[i] || 0;
      const part2 = parts2[i] || 0;

      if (part1 > part2) return 1;
      if (part1 < part2) return -1;
    }

    return 0;
  }

  /**
   * Find appropriate download URL for platform from release assets
   */
  private getDownloadUrlForPlatform(
    assets: GitHubRelease['assets'],
    platform: string,
  ): string | null {
    // Define platform-specific file patterns
    const patterns: Record<string, RegExp[]> = {
      windows: [/\.exe$/i, /windows.*\.zip$/i, /win.*\.zip$/i],
      macos: [/\.dmg$/i, /\.pkg$/i, /macos.*\.zip$/i, /darwin.*\.zip$/i],
      linux: [/\.AppImage$/i, /\.deb$/i, /\.rpm$/i, /linux.*\.zip$/i],
    };

    const platformPatterns = patterns[platform.toLowerCase()] || patterns.windows;

    for (const pattern of platformPatterns) {
      const asset = assets.find((a) => pattern.test(a.name));
      if (asset) {
        return asset.browser_download_url;
      }
    }

    this.logger.warn(
      `No download URL found for platform: ${platform}`,
    );
    return null;
  }

  /**
   * Store or update release info in database (for caching)
   */
  private async upsertUpdateRecord(
    version: string,
    build: string,
    platform: string,
    downloadUrl: string | null,
    releaseNotes: string,
  ): Promise<void> {
    try {
      // Check if this version already exists
      const existing = await this.prisma.update.findFirst({
        where: {
          version,
          platform,
        },
      });

      if (existing) {
        // Update existing record
        await this.prisma.update.update({
          where: { id: existing.id },
          data: {
            downloadUrl,
            releaseNotes,
          },
        });
      } else {
        // Create new record
        await this.prisma.update.create({
          data: {
            version,
            build,
            platform,
            downloadUrl,
            releaseNotes,
          },
        });
      }
    } catch (error: any) {
      this.logger.error(
        `Failed to store update record: ${error.message}`,
      );
    }
  }

  /**
   * Fallback: Check from database if GitHub API fails
   */
  private async checkFromDatabase(
    currentVersion: string,
    platform: string,
  ): Promise<UpdateCheckResponse> {
    const latest = await this.getLatestFromDatabase(platform);

    if (!latest) {
      return {
        updateAvailable: false,
        currentVersion,
        platform,
      };
    }

    const updateAvailable =
      this.compareVersions(latest.version, currentVersion) > 0;

    return {
      updateAvailable,
      currentVersion,
      latestVersion: latest.version,
      downloadUrl: latest.downloadUrl || undefined,
      releaseNotes: latest.releaseNotes || undefined,
      platform,
    };
  }

  /**
   * Get latest version from database
   */
  private async getLatestFromDatabase(platform: string) {
    return this.prisma.update.findFirst({
      where: { platform },
      orderBy: { createdAt: 'desc' },
    });
  }
}
