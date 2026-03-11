
package analytics

import "testing"

func TestShouldFilter(t *testing.T) {
	record := AnalyticsRecord{
		Username: "admin",
	}

	// test skip_usernames
	filter := AnalyticsFilters{
		SkippedUsernames: []string{"admin"},
	}
	shouldFilter := filter.ShouldFilter(record)
	if shouldFilter == false {
		t.Fatal("filter should be filtering the record")
	}

	// test different usernames
	filter = AnalyticsFilters{
		Usernames: []string{"james"},
	}
	shouldFilter = filter.ShouldFilter(record)
	if shouldFilter == false {
		t.Fatal("filter should be filtering the record")
	}

	// test no filter
	filter = AnalyticsFilters{}
	shouldFilter = filter.ShouldFilter(record)
	if shouldFilter == true {
		t.Fatal("filter should not be filtering the record")
	}
}

func TestHasFilter(t *testing.T) {
	filter := AnalyticsFilters{}

	hasFilter := filter.HasFilter()
	if hasFilter == true {
		t.Fatal("Has filter should be false.")
	}

	filter = AnalyticsFilters{
		Usernames: []string{"admin"},
	}
	hasFilter = filter.HasFilter()
	if hasFilter == false {
		t.Fatal("HasFilter should be true.")
	}
}
