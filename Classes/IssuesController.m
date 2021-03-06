#import "IssuesController.h"
#import "IssueController.h"
#import "GHIssue.h"


@implementation IssuesController

@synthesize repository;

- (id)initWithRepository:(GHRepository *)theRepository {
    [super initWithNibName:@"Issues" bundle:nil];
	self.title = @"Issues";
    self.repository = theRepository;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = issuesControl;
    [self setupIssues];
    if (!self.currentIssues.isLoaded) [self.currentIssues loadIssues];
}

- (void)setupIssues {
	issueList = [[NSArray alloc] initWithObjects:repository.openIssues, repository.closedIssues, nil];
	for (GHIssues *issues in issueList) [issues addObserver:self forKeyPath:kResourceStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
	issuesControl.selectedSegmentIndex = 0;
}

- (IBAction)switchChanged:(id)sender {
    [self.tableView reloadData];
    if (self.currentIssues.isLoaded) return;
    [self.currentIssues loadIssues];
    [self.tableView reloadData];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:object change:change context:context {
    if ([keyPath isEqualToString:kResourceStatusKeyPath]) {
		[self.tableView reloadData];
		GHIssues *theIssues = (GHIssues *)object;
		if (!theIssues.isLoading && theIssues.error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading error" message:@"Could not load the issues" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.currentIssues.isLoading ) || (self.currentIssues.entries.count == 0) ? 1 : self.currentIssues.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.currentIssues.isLoading) return loadingIssuesCell;
	if (self.currentIssues.entries.count == 0) return noIssuesCell;
	IssueCell *cell = (IssueCell *)[tableView dequeueReusableCellWithIdentifier:kIssueCellIdentifier];
	if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"IssueCell" owner:self options:nil];
		cell = issueCell;
	}
	cell.issue = [self.currentIssues.entries objectAtIndex:indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	GHIssue *issue = [self.currentIssues.entries objectAtIndex:indexPath.row];
	IssueController *issueController = [[IssueController alloc] initWithIssue:issue];
	[self.navigationController pushViewController:issueController animated:YES];
	[issueController release];
}

- (GHIssues *)currentIssues {
	return issuesControl.selectedSegmentIndex == UISegmentedControlNoSegment ? 
		nil : [issueList objectAtIndex:issuesControl.selectedSegmentIndex];
}

- (void)dealloc {
	for (GHIssues *issues in issueList) [issues removeObserver:self forKeyPath:kResourceStatusKeyPath];
	[issuesControl release];
	[loadingIssuesCell release];
	[noIssuesCell release];
	[issueCell release];
    [issueList release];
    [repository release];
    [super dealloc];
}

@end

