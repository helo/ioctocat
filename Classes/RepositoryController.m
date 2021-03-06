#import "GHUser.h"
#import "GHRepository.h"
#import "GHCommit.h"
#import "LabeledCell.h"
#import "TextCell.h"
#import "RepositoryController.h"
#import "UserController.h"
#import "WebController.h"
#import "iOctocatAppDelegate.h"
#import "FeedEntryCell.h"
#import "FeedEntryController.h"
#import "IssueController.h"
#import "IssueCell.h"
#import "RecentCommitsController.h"
#import "IssuesController.h"
#import "NetworkCell.h"
#import "NetworksController.h"

@interface RepositoryController ()
- (void)displayRepository;
@end


@implementation RepositoryController

- (id)initWithRepository:(GHRepository *)theRepository {
    [super initWithNibName:@"Repository" bundle:nil];
	repository = [theRepository retain];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[repository addObserver:self forKeyPath:kResourceStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
	self.title = repository.name;
	self.tableView.tableHeaderView = tableHeaderView;
	nameLabel.text = repository.name;
	(repository.isLoaded) ? [self displayRepository] : [repository loadRepository];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActions:)];

}

- (GHUser *)currentUser {
	iOctocatAppDelegate *appDelegate = (iOctocatAppDelegate *)[[UIApplication sharedApplication] delegate];
	return appDelegate.currentUser;
}

- (IBAction)showActions:(id)sender {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Actions" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:([self.currentUser isWatching:repository] ? @"Stop Watching" : @"Watch"), @"Open in GitHub",  nil];
	[actionSheet showInView:self.view.window];
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSString *newWatchState = [self.currentUser isWatching:repository] ? kUnWatch: kWatch;
        [self.currentUser setWatchingState:newWatchState forRepository:repository];            
    }
	if (buttonIndex == 1) {
        NSString *urlString = [NSString stringWithFormat:kRepositoryUrl, repository.owner, repository.name];
        NSURL *theURL = [NSURL URLWithString:urlString];
		WebController *webController = [[WebController alloc] initWithURL:theURL];
		[self.navigationController pushViewController:webController animated:YES];
		[webController release];             
    }
    
}

#pragma mark -
#pragma mark Actions

- (void)displayRepository {
    iconView.image = [UIImage imageNamed:(repository.isPrivate ? @"private.png" : @"public.png")];
	nameLabel.text = repository.name;
	numbersLabel.text = repository.isLoaded ? [NSString stringWithFormat:@"%d %@ / %d %@", repository.watchers, repository.watchers == 1 ? @"watcher" : @"watchers", repository.forks, repository.forks == 1 ? @"fork" : @"forks"] : @"";
    if ( repository.isFork ) forkLabel.text = @"forked";
	[ownerCell setContentText:repository.owner];
	[websiteCell setContentText:[repository.homepageURL host]];
	[descriptionCell setContentText:repository.descriptionText];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:object change:change context:context {
	if ([keyPath isEqualToString:kResourceStatusKeyPath]) {
		if (repository.isLoaded) {
			[self displayRepository];
			[self.tableView reloadData];
		} else if (repository.error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading error" message:@"Could not load the repository" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (repository.isLoaded) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (!repository.isLoaded) return 1;
	if (section == 0) return descriptionCell.hasContent ? 3 : 2;
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	UITableViewCell *cell;
	if (!repository.isLoaded) return loadingCell;
	if (section == 0) {
        if (row == 0) cell = ownerCell;             
        if (row == 1) cell = websiteCell;
        if (row == 2) cell = descriptionCell;
		if (indexPath.row != 2) {
			cell.selectionStyle = [(LabeledCell *)cell hasContent] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
			cell.accessoryType = [(LabeledCell *)cell hasContent] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		}
	} else if (section == 1) {
		if (row == 0) cell = commitsCell;
        if (row == 1) cell = issuesCell;
        if (row == 2) cell = networkCell;        
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	if (section == 0 && row == 0 && repository.user) {
		UserController *userController = [(UserController *)[UserController alloc] initWithUser:repository.user];
		[self.navigationController pushViewController:userController animated:YES];
		[userController release];
	} else if (section == 0 && row == 1 && repository.homepageURL) {
		WebController *webController = [[WebController alloc] initWithURL:repository.homepageURL];
		[self.navigationController pushViewController:webController animated:YES];
		[webController release];
	} else if (section == 1 && row == 0) {
		RecentCommitsController *commitsController = [[RecentCommitsController alloc] initWithFeed:repository.recentCommits];
		[self.navigationController pushViewController:commitsController animated:YES];
		[commitsController release];
	} else if (section == 1 && row == 1) {
		IssuesController *issuesController = [[IssuesController alloc] initWithRepository:repository];
		[self.navigationController pushViewController:issuesController animated:YES];
		[issuesController release];
	} else if (section == 1 && row == 2) {
		NetworksController  *networksController = [[NetworksController alloc] initWithRepository:repository];
		[self.navigationController pushViewController:networksController animated:YES];
		[networksController release];
        
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 2) return [(TextCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath] height];
	return [(UITableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
	[repository removeObserver:self forKeyPath:kResourceStatusKeyPath];
	[repository release];
	[tableHeaderView release];
	[nameLabel release];
	[numbersLabel release];
	[ownerLabel release];
	[websiteLabel release];
	[descriptionLabel release];	
	[loadingCell release];
	[ownerCell release];
    [forkLabel release];
	[websiteCell release];
	[descriptionCell release];
    [issuesCell release];
    [iconView release];
    [super dealloc];
}

@end
