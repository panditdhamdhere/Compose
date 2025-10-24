/**
 * Post coverage comment workflow script
 * Downloads coverage artifact from a workflow run and posts/updates PR comment
 * 
 * This script is designed to run in a workflow_run triggered workflow
 * with proper permissions to comment on PRs from forks.
 */

module.exports = async ({ github, context }) => {
  const fs = require('fs');
  const path = require('path');
  const { execSync } = require('child_process');
  
  console.log('Starting coverage comment posting process...');
  
  // Download artifact
  console.log('Fetching artifacts from workflow run...');
  const artifacts = await github.rest.actions.listWorkflowRunArtifacts({
    owner: context.repo.owner,
    repo: context.repo.repo,
    run_id: context.payload.workflow_run.id,
  });
  
  const coverageArtifact = artifacts.data.artifacts.find(
    artifact => artifact.name === 'coverage-data'
  );
  
  if (!coverageArtifact) {
    console.log('❌ No coverage artifact found');
    console.log('Available artifacts:', artifacts.data.artifacts.map(a => a.name).join(', '));
    return;
  }
  
  console.log('✓ Found coverage artifact, downloading...');
  
  const download = await github.rest.actions.downloadArtifact({
    owner: context.repo.owner,
    repo: context.repo.repo,
    artifact_id: coverageArtifact.id,
    archive_format: 'zip',
  });
  
  // Save and extract the artifact using execSync
  const artifactPath = path.join(process.env.GITHUB_WORKSPACE, 'coverage-data.zip');
  fs.writeFileSync(artifactPath, Buffer.from(download.data));
  
  console.log('✓ Artifact downloaded, extracting...');
  
  // Unzip the artifact
  execSync(`unzip -o ${artifactPath} -d ${process.env.GITHUB_WORKSPACE}`);
  
  // Extract PR number
  const prDataPath = path.join(process.env.GITHUB_WORKSPACE, 'coverage-data.txt');
  
  if (!fs.existsSync(prDataPath)) {
    console.log('❌ coverage-data.txt not found in artifact');
    console.log('Extracted files:', execSync(`ls -la ${process.env.GITHUB_WORKSPACE}`).toString());
    return;
  }
  
  const prData = fs.readFileSync(prDataPath, 'utf8');
  const prMatch = prData.match(/PR_NUMBER=(\d+)/);
  
  if (!prMatch) {
    console.log('❌ Could not find PR number in coverage-data.txt');
    console.log('File contents:', prData);
    return;
  }
  
  const prNumber = parseInt(prMatch[1]);
  console.log(`✓ Processing coverage for PR #${prNumber}`);
  
  // Read coverage report
  const reportPath = path.join(process.env.GITHUB_WORKSPACE, 'coverage-report.md');
  
  if (!fs.existsSync(reportPath)) {
    console.log('❌ coverage-report.md not found in artifact');
    return;
  }
  
  const body = fs.readFileSync(reportPath, 'utf8');
  console.log('✓ Coverage report loaded');
  
  // Check if a coverage comment already exists
  console.log('Checking for existing coverage comments...');
  const comments = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: prNumber
  });
  
  const botComment = comments.data.find(comment => 
    comment.user.type === 'Bot' && 
    comment.body.includes('## Coverage Report')
  );
  
  if (botComment) {
    // Update existing comment
    console.log(`Updating existing comment (ID: ${botComment.id})...`);
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: botComment.id,
      body: body
    });
    console.log('✅ Coverage comment updated successfully!');
  } else {
    // Create new comment
    console.log('Creating new coverage comment...');
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: prNumber,
      body: body
    });
    console.log('✅ Coverage comment posted successfully!');
  }
};

