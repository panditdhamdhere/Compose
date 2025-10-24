const fs = require('fs');

// Configuration thresholds
const THRESHOLDS = {
  good: 80,
  needsImprovement: 60,
  poor: 40
};

/**
 * Parse lcov.info file and extract coverage metrics
 * @param {string} content - The lcov.info file content
 * @returns {object} Coverage metrics
 */
function parseLcovContent(content) {
  const lines = content.split('\n');
  let totalLines = 0;
  let coveredLines = 0;
  let totalFunctions = 0;
  let coveredFunctions = 0;
  let totalBranches = 0;
  let coveredBranches = 0;

  // LF:, LH:, FNF:, FNH:, BRF:, BRH: are on separate lines
  // We need to track them separately and sum them up
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Lines Found and Lines Hit
    if (line.startsWith('LF:')) {
      totalLines += parseInt(line.substring(3)) || 0;
    }
    if (line.startsWith('LH:')) {
      coveredLines += parseInt(line.substring(3)) || 0;
    }

    // Functions Found and Functions Hit
    if (line.startsWith('FNF:')) {
      totalFunctions += parseInt(line.substring(4)) || 0;
    }
    if (line.startsWith('FNH:')) {
      coveredFunctions += parseInt(line.substring(4)) || 0;
    }

    // Branches Found and Branches Hit
    if (line.startsWith('BRF:')) {
      totalBranches += parseInt(line.substring(4)) || 0;
    }
    if (line.startsWith('BRH:')) {
      coveredBranches += parseInt(line.substring(4)) || 0;
    }
  }

  return {
    totalLines,
    coveredLines,
    totalFunctions,
    coveredFunctions,
    totalBranches,
    coveredBranches
  };
}

/**
 * Calculate coverage percentage
 * @param {number} covered - Number of covered items
 * @param {number} total - Total number of items
 * @returns {number} Coverage percentage
 */
function calculateCoverage(covered, total) {
  return total > 0 ? Math.round((covered / total) * 100) : 0;
}

/**
 * Get badge color based on coverage percentage
 * @param {number} coverage - Coverage percentage
 * @returns {string} Badge color
 */
function getBadgeColor(coverage) {
  if (coverage >= THRESHOLDS.good) return 'brightgreen';
  if (coverage >= THRESHOLDS.needsImprovement) return 'yellow';
  if (coverage >= THRESHOLDS.poor) return 'orange';
  return 'red';
}

/**
 * Generate coverage report comment body
 * @param {object} metrics - Coverage metrics
 * @returns {string} Markdown formatted comment body
 */
function generateCoverageReport(metrics) {
  const lineCoverage = calculateCoverage(metrics.coveredLines, metrics.totalLines);
  const functionCoverage = calculateCoverage(metrics.coveredFunctions, metrics.totalFunctions);
  const branchCoverage = calculateCoverage(metrics.coveredBranches, metrics.totalBranches);

  const badgeColor = getBadgeColor(lineCoverage);
  const badge = `![Coverage](https://img.shields.io/badge/coverage-${lineCoverage}%25-${badgeColor})`;

  return `## Coverage Report\n` +
    `${badge}\n\n` +
    `| Metric | Coverage | Details |\n` +
    `|--------|----------|----------|\n` +
    `| **Lines** | ${lineCoverage}% | ${metrics.coveredLines}/${metrics.totalLines} lines |\n` +
    `| **Functions** | ${functionCoverage}% | ${metrics.coveredFunctions}/${metrics.totalFunctions} functions |\n` +
    `| **Branches** | ${branchCoverage}% | ${metrics.coveredBranches}/${metrics.totalBranches} branches |\n\n`;
}

/**
 * Main function to post coverage comment
 * @param {object} github - GitHub API object
 * @param {object} context - GitHub Actions context
 */
async function postCoverageComment(github, context) {
  const file = 'lcov.info';

  if (!fs.existsSync(file)) {
    console.log('Coverage file not found.');
    return;
  }

  const content = fs.readFileSync(file, 'utf8');
  const metrics = parseLcovContent(content);

  console.log('Coverage Metrics:');
  console.log('- Lines:', metrics.coveredLines, '/', metrics.totalLines);
  console.log('- Functions:', metrics.coveredFunctions, '/', metrics.totalFunctions);
  console.log('- Branches:', metrics.coveredBranches, '/', metrics.totalBranches);

  const body = generateCoverageReport(metrics);

  await github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body: body
  });

  console.log('Coverage comment posted successfully!');
}

module.exports = { postCoverageComment };

