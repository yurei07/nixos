import click
import subprocess
import os

file_check = 'check.txt'

@click.group()
def cli_git():
    click.echo('My application git CLI')

@cli_git.command()
@click.option('--choice', prompt='Your choice', help='Choise of commands: v = version, l = log, s = show')

def choice(choice):
    v = subprocess.run(['git', '--version'], text=True, capture_output=True)

    result_v = v.stdout.strip()

    match choice:
        case 'v':
            click.echo(f'It is your {result_v}. You are welcome!:)')
        case 'l':
            subprocess.run(['git', 'log'])
        case 's':
            subprocess.run(['git', 'show'])

@cli_git.command()
@click.option('--combo', prompt='Your combo', type=str, help='Combo creates commit and saves files in the Git of the repository')

def combo(combo):
    match combo:
        case 'pull':
            if  os.path.exists(file_check):
                os.system('rm -rf ./flake.lock ./flake.nix ./hosts ./materials ./modules ./scripts ')
                os.system('cp -r /etc/nixos/* ./')
                os.system('git add . --all')
                
                value = input('Enter commit name (enter to default): ')

                if value != '':
                    os.system(f'git commit -m "{value}"')
                    os.system('git pull')
                    os.system('git push -u')
                elif value == '':
                    os.system('git commit -m "update"')
                    os.system('git pull')
                    os.system('git push -u')
                    


if __name__ == '__main__':
    cli_git()
