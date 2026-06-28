# WestpacAssessment

Native SwiftUI GitHub repository explorer for the Westpac coding assessment.

The app fetches public repositories from `https://api.github.com/repositories`, displays them in grouped sections, supports local favourites, handles loading and error states, and loads additional pages using GitHub's `Link` header `rel="next"` URL.

## File Structure

The app is organised by feature under `WestpacAssessment/WestpacAssessment/Features`.

```text
WestpacAssessment/
  WestpacAssessment/
    ContentView.swift
    WestpacAssessmentApp.swift
    Features/
      Repositories/
        RepositoryListView.swift
        RepositoryListViewModel.swift
        Data/
          GitHubAPIClient.swift
          GitHubRepository.swift
        Views/
          RepositoryRowView.swift
          RepositoryDetailView.swift
      Bookmarks/
        Model/
          BookmarkStore.swift
          RepositoryBookmarking.swift
      Mock/
        GitHubRepositoryMockData.swift
        MockGitHubRepositoryClient.swift
  WestpacAssessmentTests/
  WestpacAssessmentUITests/
```

### Repositories

`Repositories` owns the main list and detail experience.

`RepositoryListViewModel` contains the screen state, grouping logic, bookmark forwarding, metadata prefetching, refresh behaviour, and pagination. Pagination is triggered only by the bottom loading row appearing at the end of the list. While the next page is loading, the list shows a `ProgressView("Loading more")` row.

`Data` contains the GitHub API client and repository models. `GitHubAPIClient` follows the HTTP `Link` header instead of guessing page numbers.

`Views` contains reusable repository UI components:

- `RepositoryRowView`
- `RepositoryDetailView`

### Bookmarks

`Bookmarks` owns local favourite persistence.

`BookmarkStore` stores bookmarked repository IDs in `UserDefaults`. `RepositoryBookmarking` keeps bookmark-related behaviour separate from the repository feature.

### Mock

`Mock` contains deterministic test data and a fake client:

- `GitHubRepositoryMockData` contains repository JSON based on the sample API response, plus detail and language metadata.
- `MockGitHubRepositoryClient` implements the same repository service protocol as the real GitHub client.

The app switches to mock mode when launched with:

```text
--mock-github
```

UI tests also use:

```text
MOCK_GITHUB_SCENARIO=populated|empty|rateLimited|networkError
UITEST_RESET_BOOKMARKS=1
```

This lets UI tests run without network access and with a clean bookmark state.

## Tests

### Unit Tests

`WestpacAssessmentTests` covers:

- Decoding a public GitHub repository response when optional detail fields are missing.
- Parsing GitHub pagination `Link` headers and extracting `rel="next"`.
- Decoding the mock repository data from the sample response.
- Mock client paging, detail metadata, and language metadata.
- Mock client error scenarios, including API rate limiting.
- Grouping repositories by fork status.
- Grouping repositories by owner type.
- Grouping repositories by language, including fetched language metadata overriding list data.
- Grouping repositories by stargazer bands in the expected display order.
- Bookmark persistence in `UserDefaults`.

### UI Tests

`WestpacAssessmentUITests` covers:

- Rendering mock repositories.
- Favouriting a repository on the detail screen, returning to the list, and verifying the star appears on that row.
- Removing a favourite from the detail screen.
- Detail screen summary content.
- Detail screen metadata: owner, owner type, fork status, stars, and languages.
- Detail screen GitHub link presence.
- Grouping UI for fork status.
- Grouping UI for language.
- Grouping UI for stargazer bands.
- Empty state rendering without network access.
