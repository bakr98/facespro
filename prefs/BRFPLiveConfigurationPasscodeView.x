#import "BRFPLiveConfigurationPasscodeView.h"
#import <SpringBoardUIServices/SBUIPasscodeLockNumberPad.h>
#import <SpringBoardUIServices/SBPasscodeNumberPadButton.h>
#import <Cephei/HBPreferences.h>
#import <libcolorpicker.h>
#import <Preferences/PreferencesAppController.h>
#import <PreferencesUI/PSUIPrefsRootController.h>

#define FACES_BUTTON_TAG 19828
#define FACES_COLOR_TAG 19829

@implementation BRFPLiveConfigurationPasscodeView {
	SBPasscodeNumberPadButton *_selectedButton;
	HBPreferences *_preferences;
}

#pragma mark BRFPLiveConfigurationPasscodeView

- (instancetype)initWithLightStyle:(BOOL)lightStyle {
	if (self = [super initWithLightStyle:lightStyle]) {
		_preferences = [[HBPreferences alloc] initWithIdentifier:@"me.benrosen.facespro"];
	}
	return self;
}

- (void)passcodeLockNumberPad:(SBUIPasscodeLockNumberPad *)numberPad keyUp:(SBPasscodeNumberPadButton *)passcodeButton {
	_selectedButton = passcodeButton;

	UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"Faces Pro" message:[NSString stringWithFormat:@"You selected button %@. What would you like to do to this button?", passcodeButton.stringCharacter] preferredStyle:UIAlertControllerStyleActionSheet];
	optionsAlert.popoverPresentationController.sourceView = passcodeButton;

	[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Take a new Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self setNewImageWithNewPhoto:YES];
	}]];

	[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Choose an Existing Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self setNewImageWithNewPhoto:NO];
	}]];

	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/var/mobile/Library/Faces/picture%@.png", [passcodeButton stringCharacter]]]) {
		[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Delete current photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self passcodeButtonShouldDeleteImage];
		}]];
	}

	[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

	[((PreferencesAppController *)[UIApplication sharedApplication]).rootController presentViewController:optionsAlert animated:YES completion:nil];
}

#pragma mark ellipsis

- (void)ellipsisPressed:(UIBarButtonItem *)item {
	NSString *tint = [_preferences objectForKey:@"tint"];
	UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"Faces Pro" message:@"What you like to do to all of the buttons?" preferredStyle:UIAlertControllerStyleActionSheet];
	[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Set a background tint color images" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		UIColor *startColor = LCPParseColorString(tint, @"#000000");
		PFColorAlert *alert = [PFColorAlert colorAlertWithStartColor:startColor showAlpha:NO];
		[alert displayWithCompletion:^(UIColor *pickedColor){
			[optionsAlert release];
			NSString *hexString = [UIColor hexFromColor:pickedColor];
			[_preferences setObject:hexString forKey:@"tint"];

			[self setAllButtonsBackgroundColorToColor:pickedColor];
		}];
	}]];

	if (tint) {
		[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Remove background tint color for images" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[_preferences removeObjectForKey:@"tint"];
		    [UIView animateWithDuration:2 animations:^{
		        [self setAllButtonsBackgroundColorToColor:[UIColor clearColor]];
		    }];
		}]];
	}

	[optionsAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

	[((PreferencesAppController *)[UIApplication sharedApplication]).rootController presentViewController:optionsAlert animated:YES completion:nil];
}

#pragma mark color modification

- (void)setAllButtonsBackgroundColorToColor:(UIColor *)color {
	[UIView animateWithDuration:2 animations:^{
		for (SBPasscodeNumberPadButton *button in self._numberPad.buttons) {
			if ([button isKindOfClass:%c(SBPasscodeNumberPadButton)]) {
				UIView *colorView = [button.revealingRingView viewWithTag:FACES_COLOR_TAG];
				colorView.backgroundColor = color;
			}
		}
	}];
}

#pragma mark image modification

- (void)setNewImageWithNewPhoto:(BOOL)newPhoto {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = newPhoto ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.allowsEditing = YES;
	imagePicker.delegate = self;

	[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)passcodeButtonShouldDeleteImage {
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/var/mobile/Library/Faces/picture%@.png", [_selectedButton stringCharacter]] error:nil];
	[self putImageOnSelectedButton:[[UIImage alloc] init]];
}

- (void)putImageOnSelectedButton:(UIImage *)image {
	TPRevealingRingView *ringView = _selectedButton.revealingRingView;
	UIImageView *pictureImageView = (UIImageView *)[ringView viewWithTag:FACES_BUTTON_TAG];
	CGFloat imageAlpha = pictureImageView.alpha;
	//UIColor *averageColor = [image dominantColor];

	[UIView animateWithDuration:2 animations:^{
		pictureImageView.alpha = 0.0;
		pictureImageView.image = image;
		pictureImageView.alpha = imageAlpha;
	   // pictureImageView.layer.borderColor = averageColor.CGColor ? : [UIColor clearColor].CGColor;
	}];
}

#pragma mark image picker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *picture = info[UIImagePickerControllerEditedImage];
	NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Faces/picture%@.png", [_selectedButton stringCharacter]];
	NSData *imageData = UIImagePNGRepresentation(picture);
	[imageData writeToFile:path atomically:YES];
	[picker dismissViewControllerAnimated:YES completion:^{
		[self putImageOnSelectedButton:picture];
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark memory management

- (void)dealloc {
	[super dealloc];

	[_selectedButton release];
}

@end
