import json
import sys
import argparse

# Mapping tags to readable Status names
TAG_MAPPING = {
    '@new_issue': 'New and reported',
    '@under_debugging': 'Debugging',
    '@bug_reported': 'Bug reported',
    '@test_issue': 'Test Framework issue',
    '@flaky': 'Flaky Test'
}

def get_status(tags):
    """Determines status based on tags. Returns 'Not reported' if no matching tag found."""
    found_status = 'Not reported'
    # Priority order can be adjusted here if needed
    for tag in tags:
        tag_name = tag.get('name')
        if tag_name in TAG_MAPPING:
            found_status = TAG_MAPPING[tag_name]
            # Stop at the first relevant tag found (or remove break to prioritize last)
            break
    return found_status

def generate_summary(json_file_path):
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            features = json.load(f)
    except Exception as e:
        print(f"Error reading JSON file: {e}")
        sys.exit(1)

    failed_features_count = 0
    total_failed_scenarios = 0
    status_counts = {val: 0 for val in TAG_MAPPING.values()}
    status_counts['Not reported'] = 0
    output_lines = []

    for feature in features:
        feature_name = feature.get('name', 'Unknown Feature')
        elements = feature.get('elements', [])
        feature_tags = feature.get('tags', [])

        feature_has_failure = False
        first_failure_recorded = False

        for scenario in elements:
            # Check if this element is a scenario (not background) and if it failed
            if scenario.get('type') != 'scenario':
                continue

            # Check steps for any failure
            steps = scenario.get('steps', [])
            is_failed = any(step.get('result', {}).get('status') == 'failed' for step in steps)

            if is_failed:
                total_failed_scenarios += 1
                feature_has_failure = True

                # Merge Scenario tags with Feature tags
                scenario_tags = scenario.get('tags', [])
                all_tags = feature_tags + scenario_tags

                # Determine Status
                status = get_status(all_tags)
                status_counts[status] += 1

                # Record ONLY the first failed scenario for the list
                if not first_failure_recorded:
                    scenario_title = scenario.get('name', 'Unnamed Scenario')
                    output_lines.append(f"* {feature_name}")
                    output_lines.append(f"    * [{status}] {scenario_title}")
                    first_failure_recorded = True

        if feature_has_failure:
            failed_features_count += 1

    # --- Print The Report ---
    print("=" * 21)
    print(" TEST REVIEW SUMMARY ")
    print("=" * 21 + "\n")

    print(f"- Failed Features: {failed_features_count}")
    print(f"- Failed Scenarios: {total_failed_scenarios}")

    # Format Breakdown
    breakdown = [f" - {k}: {v}\n" for k, v in sorted(status_counts.items()) if v > 0]
    print(f"- Breakdown by Status:\n{''.join(breakdown)}")
    print("-" * 51)
    print(" List of failed features and first failed scenario ")
    print("-" * 51)
    for line in output_lines:
        print(line)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse Cucumber JSON report for summary.")
    parser.add_argument("jsonfile", help="Path to cucumber_report.html.json")
    args = parser.parse_args()

    generate_summary(args.jsonfile)
